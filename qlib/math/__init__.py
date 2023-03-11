from math import log, log2, log10
from math import remainder as rem, modf as split_fraction, floor, ceil
from typing import TypeVar

# instrinsics
# a + b
# a - b
# a * b
# a / b
# a pow b
# a mod b
# a rem b

# units
e = 2.718281828459045
tau = 6.283185307179586
tauOver2 = tau / 2
tauOver4 = tauOver2 / 2

epsilon = 1e-6

def deg(radians: float) -> float:
    return radians * 360 / tau

def rad(degrees: float) -> float:
    return degrees * tau / 360

N = TypeVar("N", bool, int, float)

def lerp(t: N, x: N, y: N) -> int | float:
    return x * (1-t) + y*t

def abs(x: float) -> float:
    return lerp((x < 0), x, -x)

def sign(x: float | int) -> int:
    return (x > 0) - (x < 0)

def ceilLog10(n: int) -> int:
    '''return ceil(log10(n)) in O(log n)'''
    acc = 0
    while n > 0:
        n = n // 10
        acc += 1
    return acc

# TODO: accurate to 0.001
def _sin(x: float, half_interval: float = tauOver2) -> float:
    '''return sin(x * half_tau/half_interval) on [0, 1] for x on [-half_interval, half_interval]'''
    y = (4/half_interval)*x - (4/half_interval**2) * x * abs(x)
    y = 0.775 * y + 0.225 * (y * abs(y))
    return y

# TODO: also accurate to 0.001
def _sin2(x: float):
    # Bhaskara's approximation
    k = 5/4*tauOver2**2
    xd = x*(tauOver2-x)
    return 4*xd / (k - xd)

def sin(x: float) -> float:
    '''return sin(x) on [0, 1] for x on (-inf, inf)'''
    return _sin(tauOver2 - (x%tau))

def cos(x: float) -> float:
    '''return cos(x) on [0, 1] for x on (-inf, inf)'''
    return sin(x + tauOver4)

def Gamma(x: int | float) -> float:
    '''return Gamma(x) in O(log x)'''
    y = (2*x + 1/3)**.5 * tauOver2**.5 * x**x * e**(-x)
    if x < 0:
        return tauOver2 / (sin(tauOver2 * x) * y)
    else:
        return y

from .search import *

# TODO: try doing path tracing
# TODO: PGA + RK4 or something for game logic
