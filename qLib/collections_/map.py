from typing import Any, Generic, TypeVar, cast
from qLib.collections_ import reduce
from qLib.tests import assert_greater_than_equals, assert_less_than_equals, assert_not_equals

def _hash(value: Any) -> int:
    if isinstance(value, str):
        return reduce(value, lambda a, v: a ^ _hash(ord(v)), 0)
    else:
        return value ^ (value >> 1)

K = TypeVar("K")
V = TypeVar("V")
class _MapSlotState:
    # TODO: use a ref counter so we can set slots back to .Empty?
    Empty = 0
    Filled = 1
    Deleted = 2

class _MapItem(Generic[K, V]):
    def __init__(self, key: K, value: V):
        self.key = key
        self.value = value
    def __repr__(self):
        return f"<key={self.key}; value={self.value}>"

class _MapSlot(Generic[K, V]):
    def __init__(self, item: _MapItem[K, V], state: int):
        self.item = item
        self.state = state
    def __repr__(self):
        return f"<item={self.item}; state={self.state}>"

_MAP_LOAD_FACTOR_PERCENT = 75
class BaseMap(Generic[K, V]):
    def __init__(self, slot_count=4):
        self.size = 0
        self.data: list[_MapSlot[K, V]] = [cast(_MapSlot[K, V], _MapSlot(_MapItem(None, None), 0))] * slot_count

    def items(self) -> list[_MapItem[K, V]]:
        acc: list[_MapItem[K, V]] = []
        for slot in self.data:
            if slot.state == _MapSlotState.Filled:
                acc.append(slot.item)
        return acc

    def _resizeTo(self, n: int):
        self.data = [cast(_MapSlot[K, V], _MapSlot(_MapItem(None, None), 0))] * n
        self.size = 0
    def _growIfNecessary(self):
        if (self.size * 100) >= (len(self.data) * _MAP_LOAD_FACTOR_PERCENT):
            items = self.items()
            self._resizeTo(len(self.data)*2 + (len(self.data) == 0)*4)
            for item in items:
                self._set(item.key, item.value)

    def _indexOf(self, key: K) -> int:
        assert_greater_than_equals(len(self.data), 0)
        h = _hash(key)
        i = h % len(self.data)
        while 1:
            if self.data[i].state == _MapSlotState.Empty:
                return -1
            elif self.data[i].state == _MapSlotState.Filled:
                if (self.data[i].item.key == key): return i
            h >>= 5
            i = (5*i + 5 + h) % len(self.data) # Note(Patrolin): 5*i + 5 wouldn't repeat, but this can, however we want to avoid long blocks of .Filled slots
            # ...and we want to mitigate Hash flooding
        return 0 # make compiler happy

    def has(self, key: K) -> bool:
        return self._indexOf(key) != -1
    def remove(self, key: K):
        i = self._indexOf(key)
        self.size -= (i != -1)
        self.data[i].state = _MapSlotState.Deleted
    def _set(self, key: K, value: V):
        self._growIfNecessary()
        h = _hash(key)
        i = h % len(self.data)
        while 1:
            if self.data[i].state == _MapSlotState.Filled:
                if self.data[i].item.key == key:
                    self.data[i].item.value = value
                    return
            else:
                assert_less_than_equals(self.size + 1, len(self.data))
                self.data[i] = _MapSlot(_MapItem(key, value), _MapSlotState.Filled)
                self.size += 1
                return
            h >>= 5
            i = (5*i + 5 + h) % len(self.data)
    def _get(self, key: K) -> V:
        assert_greater_than_equals(len(self.data), 1)
        i = self._indexOf(key)
        assert_not_equals(i, -1)
        return self.data[i].item.value

    def __iter__(self):
        for slot in self.data:
            if slot.state == _MapSlotState.Filled:
                yield slot.item.key, slot.item.value

class Map(BaseMap[K, V]):
    def __getitem__(self, key: K):
        return self._get(key)

    def __setitem__(self, key: K, value: V):
        self._set(key, value)

    def __repr__(self):
        return "{" + ", ".join(f"{repr(key)}: {value}" for key, value in self) + "}"

class Set(BaseMap[K, None]):
    def __getitem__(self, key: K):
        return self.has(key)

    def add(self, key: K):
        self._set(key, None)

    def __repr__(self):
        return "{" + ", ".join(repr(key) for key, value in self) + "}"
