from typing import Any

class LinkedListSlot:
    def __init__(self, value: Any):
        self.next: LinkedListSlot = self
        self.previous: LinkedListSlot = self
        self.value = value

class LinkedList:
    def __init__(self, values: list[Any] = []):
        self.count = 0
        self.head = LinkedListSlot(None)
        for v in values:
            self.push(v)

    def __repr__(self):
        return "[" + ", ".join(repr(v) for v in self) + "]"

    def __iter__(self):
        curr = self.head
        for i in range(self.count):
            curr = curr.next
            yield curr.value

    def __getitem__(self, i):
        if i >= self.count:
            raise IndexError
        curr = self.head
        for j in range(i+1):
            curr = curr.next
        return curr.value

    def __setitem__(self, i, value):
        self[i].value = value

    def index(self, value) -> int:
        curr = self.head
        for i in range(self.count):
            curr = curr.next
            if curr.value == value:
                return i
        return -1

    def has(self, key) -> bool:
        return self.index(key) != -1

    def push(self, value):
        new_slot = LinkedListSlot(value)
        previous = self.head.previous
        new_slot.previous = previous
        previous.next = new_slot
        self.head.previous = new_slot
        self.count += 1

    def pushLeft(self, value):
        new_slot = LinkedListSlot(value)
        next = self.head.next
        new_slot.next = next
        next.previous = new_slot
        self.head.next = new_slot
        self.count += 1

    def pop(self):
        if self.count == 0:
            raise IndexError
        previous = self.head.previous
        value = previous.value
        self.head.previous = previous.previous
        self.count -= 1
        return value

    def popLeft(self):
        if self.count == 0:
            raise IndexError
        next = self.head.next
        value = next.value
        self.head.next = next.next
        self.count -= 1
        return value
