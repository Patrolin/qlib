from typing import Callable, Iterable, Generic, TypeVar

from ..tests import assert_never

V = TypeVar("V")
class Slice(Generic[V]):
    def __init__(self, ptr: list, start: int, end: int):
        self.ptr = ptr
        self.start = start
        self.end = end
    def __getitem__(self, key):
        i = key + self.start
        assert_less_than_equals(i, self.end)
        return self.ptr[i]

def find(arr: Iterable[V], matches: Callable[[V], bool]) -> V:
    for v in arr:
        if matches(v): return v
    assert_never(f"Couldn't find match in {arr}")

def findOrNone(arr: Iterable[V], matches: Callable[[V], bool]) -> V|None:
    for v in arr:
        if matches(v): return v
    return None

def findIndex(arr: Iterable[V], matches: Callable[[V], bool]) -> int:
    for i, v in enumerate(arr):
        if matches(v): return i
    assert_never(f"Couldn't find match in {arr}")

def findIndexOrDefault(arr: Iterable[V], matches: Callable[[V], bool], default: int = -1) -> int:
    for i, v in enumerate(arr):
        if matches(v): return i
    return default

A = TypeVar("A")
def reduce(arr: Iterable[V], f: Callable[[A, V], A], acc: A):
    for v in arr:
        acc = f(acc, v)
    return acc

def enum(cls):
    def __init__(self, value):
        self.value = value
    setattr(cls, "__init__", __init__)
    def __repr__(self):
        return f"(value={self.value})"
    setattr(cls, "__repr__", __repr__)
    for k in cls.__dict__:
        if k[0] != "_":
            setattr(cls, k, cls(cls.__dict__[k]))
    return cls

def flags(cls):
    def __init__(self, value):
        self.value = value
    setattr(cls, "__init__", __init__)
    def __getattribute__(self, key):
        if key.upper() == key:
            # TODO: support groups
            value = getattr(cls, key).value
            return (self.value & value) == value
        return object.__getattribute__(self, key)
    setattr(cls, "__getattribute__", __getattribute__)
    def __getitem__(self, key):
        return self.__getattribute__(key)
    setattr(cls, "__getitem__", __getitem__)
    keys = []
    def __repr__(self):
        return "|".join(str(key) for key in keys if self[key])
    setattr(cls, "__repr__", __repr__)
    for k in cls.__dict__:
        if k[0] != "_":
            keys.append(k)
            setattr(cls, k, cls(cls.__dict__[k]))
    return cls

class Flags:
    @classmethod
    def toString(cls, value):
        Group = list[tuple[str, int]]
        def groupTogether(groups: list[Group]) -> list[Group]:
            acc: list[Group] = []
            for g1 in groups:
                for g2 in acc:
                    if any(f1 & f2 for k1, f1 in g1 for k2, f2 in g2):
                        g2.extend(g1)
                        break
                else:
                    acc.append(g1)
            return groups
        def best_match(group: Group, value: int) -> tuple[str, int]:
            mask = 0
            for k, f in group:
                mask |= f
            for k, f in group:
                if (value & mask) == f:
                    return k, f
            return "", 0
        flagAndKeyGroups: list[Group] = []
        for k in dir(cls):
            if k.startswith("__"): break
            flagAndKeyGroups.append([(k, cls.__dict__[k])])
            while True:
                new = groupTogether(flagAndKeyGroups)
                if new == flagAndKeyGroups: break
                else: flagAndKeyGroups = new
        acc: list[str] = []
        for g in flagAndKeyGroups:
            k, f = best_match(g, value)
            value ^= f
            if f != 0:
                acc.append(k)
        if value != 0:
            acc.append(f"0x{value:x}")
        return " | ".join(acc)

from .linked_list import *
from .map import *
from .string import *
