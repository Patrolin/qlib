from typing import Callable, Iterable, Sequence, TypeVar

from ..tests import assert_never

V = TypeVar("V")
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

from .linked_list import *
from .map import *
from .string import *
