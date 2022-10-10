from math import log, log2, log10
from math import remainder as rem, modf, floor, ceil
from typing import Callable, Iterable, TypeVar, overload

from qLib.tests import assert_equals, assert_not_equals

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

@overload
def lerp(t: bool, x: int, y: int) -> int:
    ...

@overload
def lerp(t: float, x: float, y: float) -> float:
    ...

def lerp(t: bool | float, x: int | float, y: int | float) -> int | float:
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

def _sin(x: float, half_interval: float = tauOver2) -> float:
    '''return sin(x * half_tau/half_interval) on [0, 1] for x on [-half_interval, half_interval]'''
    y = 4/half_interval*x - 4 / half_interval**2 * x * abs(x)
    return y
    #return 0.775 * y + 0.225 * (y * abs(y))

def sin(x: float) -> float:
    '''return sin(x) on [0, 1] for x on (-inf, inf)'''
    return _sin(tauOver2 - (x%tau))

def cos(x: float) -> float:
    '''return cos(x) on [0, 1] for x on (-inf, inf)'''
    return sin(x + tauOver4)

# functions
# a + b
# a - b
# a * b
# a / b
# a ^ b
# a mod b
# a rem b

def Gamma(x: int | float) -> float:
    '''return Gamma(x) in O(log n)'''
    y = (2*x + 1/3)**.5 * tauOver2**.5 * x**x * e**(-x)
    if x < 0:
        return tauOver2 / (sin(tauOver2 * x) * y)
    else:
        return y

def bisection_solve(a: float, b: float, f: Callable[[float], float]) -> float:
    # find a root x of f(x) on the interval [min(a,b), max(a,b)]
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

phi1 = bisection_solve(1.0, 2.0, lambda x: x**2 - x - 1)
phi2 = bisection_solve(1.0, 2.0, lambda x: x**3 - x - 1)
phi3 = bisection_solve(1.0, 2.0, lambda x: x**4 - x - 1)
phi4 = bisection_solve(1.0, 2.0, lambda x: x**5 - x - 1)

# TODO: global n-dimensional optimization?

# TODO: try doing path tracing
# TODO: PGA + RK4 or something for game logic
