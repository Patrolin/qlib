from typing import TypeVar

N = TypeVar("N", int, float)

def ceilLog(n: int, base: int) -> int:
    '''return ceil(log10(n)) in O(log n)'''
    acc = 0
    while n > 0:
        n = n // base
        acc += 1
    return acc

def sign(x: N) -> int:
    return (x > 0) - (x < 0)
