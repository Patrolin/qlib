__all__ = ["LinkedList", "Set", "Map", "normalize", "string_similarity"]


# BucketArray?
from typing import Callable, Iterable, TypeVar, cast

from qLib.tests import assert_
from .linked_list import *
from .map import *
from .string import *

V = TypeVar("V")
def find(arr: Iterable[V], matches: Callable[[V], bool]) -> V:
    for v in arr:
        if matches(v): return v
    assert_(False)
    return cast(V, None) # make compiler happy
def findIndex(arr: Iterable[V], matches: Callable[[V], bool]) -> int:
    for i, v in enumerate(arr):
        if matches(v): return i
    assert_(False)
    return cast(int, None) # make compiler happy
