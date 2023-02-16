from typing import Callable, Iterable, TypeVar
from qlib.math import sign
from qlib.tests import assert_not_equals

def bisectionSolve(a: float, b: float, f: Callable[[float], float]) -> float:
    '''find a root x of f(x) on the interval [min(a,b), max(a,b)]'''
    sign_a = sign(f(a))
    assert_not_equals(sign_a, sign(f(b)))
    while True:
        # shrink the interval towards some root
        x = (a+b) / 2
        if x == a or x == b: return x
        sign_x = sign(f(x))
        if sign_x == sign_a:
            a = x
        else:
            b = x

# TODO: implicit formula + rand
phi1 = bisectionSolve(1.0, 2.0, lambda x: x**2 - x - 1)
phi2 = bisectionSolve(1.0, 2.0, lambda x: x**3 - x - 1)
phi3 = bisectionSolve(1.0, 2.0, lambda x: x**4 - x - 1)
phi4 = bisectionSolve(1.0, 2.0, lambda x: x**5 - x - 1)

# TODO: global n-dimensional optimization?

Node = TypeVar("Node")

def aStar(start: Node, neighbors: Callable[[Node], Iterable[Node]], goal: Callable[[Node], bool], heuristic: Callable[[Node],
                                                                                                                      float]) -> list[Node]:
    ... # TODO
