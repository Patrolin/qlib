__all__ = ["LinkedList", "Set", "Map", "normalize", "string_similarity"]


# BucketArray?
from typing import Callable, Iterable, TypeVar

from qLib.tests import assert_never
from .linked_list import *
from .map import *
from .string import *

V = TypeVar("V")
def find(arr: Iterable[V], matches: Callable[[V], bool]) -> V:
    for v in arr:
        if matches(v): return v
    assert_never(f"Couldn't find match in {arr}")

def findIndex(arr: Iterable[V], matches: Callable[[V], bool]) -> int:
    for i, v in enumerate(arr):
        if matches(v): return i
    assert_never(f"Couldn't find match in {arr}")
