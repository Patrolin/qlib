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
E = 2.718281828459045
TAU = 6.283185307179586
PI = TAU / 2

# TODO: split int, float?
# TODO: frexp() -> tuple[float, int]
SIGNIFICAND_BITS_64 = 52
EPSILON_64 = 2**-SIGNIFICAND_BITS_64
ROUND_TO_INTEGER_64 = 1.5 / EPSILON_64

def round(x: float) -> float:
    return x + ROUND_TO_INTEGER_64 - ROUND_TO_INTEGER_64

def deg(radians: float) -> float:
    return radians * 360 / TAU

def rad(degrees: float) -> float:
    return degrees * TAU / 360

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

# TODO: chebshev polynomial (https://en.wikipedia.org/wiki/Remez_algorithm) + horner's method approximation to ~5ULP
# (+ golden section search)
# TODO: accurate to 0.001
def _sin(x: float, half_interval: float = PI) -> float:
    '''return sin(x * half_tau/half_interval) on [0, 1] for x on [-half_interval, half_interval]'''
    # https://web.archive.org/web/20171228230531/http://forum.devmaster.net/t/fast-and-accurate-sine-cosine/9648
    y = (4/half_interval) * x - (4 / half_interval**2) * x * abs(x)
    y = 0.775*y + 0.225 * (y * abs(y))
    return y

# TODO: also accurate to 0.001
def _sin2(x: float):
    # Bhaskara's approximation
    k = 5 / 4 * PI**2
    xd = x * (PI-x)
    return 4 * xd / (k-xd)

def sin(x: float) -> float:
    '''return sin(x) on [0, 1] for x on (-inf, inf)'''
    return _sin(PI - (x%TAU))

def cos(x: float) -> float:
    '''return cos(x) on [0, 1] for x on (-inf, inf)'''
    return sin(x + TAU/4)

def Gamma(x: int | float) -> float:
    '''return Gamma(x) in O(log x)'''
    y = (2*x + 1/3)**.5 * PI**.5 * x**x * E**(-x)
    if x < 0:
        return PI / (sin(PI * x) * y)
    else:
        return y

from .search import *

# TODO: try doing path tracing
# TODO: PGA + RK4 or something for game logic
