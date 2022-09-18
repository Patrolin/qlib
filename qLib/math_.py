from math import isqrt, log, log2, log10, sin, hypot as L2
from math import remainder as rem, modf, floor, ceil
from typing import Callable, Iterable, TypeVar, overload

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

def ilog10(n: int) -> int:
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

A = TypeVar("A")
B = TypeVar("B")

def reduce(arr: Iterable[A], f: Callable[[B, A], B], acc: B):
    for v in arr:
        acc = f(acc, v)
    return acc

# functions
# a + b
# a - b
# a * b
# a / b
# a ^ b
# a mod b
# a rem b
# log(x) = (x**epsilon - 1) / epsilon

def Gamma(x: int | float) -> float:
    '''return Gamma(x) in O(log n)'''
    y = (2*x + 1/3)**.5 * tauOver2**.5 * x**x * e**(-x)
    if x < 0:
        return tauOver2 / (sin(tauOver2 * x) * y)
    else:
        return y

def bisection_solve(a: float, b: float, f: Callable[[float], float]) -> float:
    # find a root x of f(x) on [min(a,b), max(a,b)] if sign(f(a)) != sign(f(b))
    sa = sign(f(a))
    if sa == sign(f(b)):
        raise ValueError("sign(f(a)) == sign(f(b))")
    while True:
        # shrink the interval towards some root
        x = (a+b) / 2
        if x == a or x == b: return x
        sx = sign(f(x))
        if sx == sa:
            a = x
        else:
            b = x

def nelder_mead_1D(f: Callable, x1: float, x2: float) -> float:
    '''return a local minimum of a 1D f(x) in O(1) via Nelder-Mead'''
    y1 = f(x1)
    y2 = f(x2)
    if y1 < y2:
        best_x, worst_x = x1, x2
        best_y, worst_y = y1, y2
    else:
        best_x, worst_x = x2, x1
        best_y, worst_y = y2, y1
    if abs(best_x - worst_x) > epsilon:
        for i in range(100):
            centroid = worst_x
            reflection_x = 2*best_x - centroid
            expansion_x = 3*best_x - 2*centroid
            contraction_shrink_x = 0.5*best_x + 0.5*worst_x
            reflection_y = f(reflection_x)
            if reflection_y < best_y:
                expansion_y = f(expansion_x)
                if expansion_y < best_y:
                    worst_x, worst_y = best_x, best_y
                    best_x, best_y = expansion_x, expansion_y
                else:
                    worst_x, worst_y = best_x, best_y
                    best_x, best_y = reflection_x, reflection_y
            else:
                contraction_shrink_y = f(contraction_shrink_x)
                if contraction_shrink_y < best_y:
                    worst_x, worst_y = best_x, best_y
                    best_x, best_y = contraction_shrink_x, contraction_shrink_y
                else:
                    worst_x, worst_y = contraction_shrink_x, contraction_shrink_y
            if abs(best_x - worst_x) <= epsilon:
                break
    if abs(best_x - worst_x) > epsilon:
        raise ValueError()
    return best_x

# TODO: globally optimize

phi1 = bisection_solve(1.0, 2.0, lambda x: x**2 - x - 1)
phi2 = bisection_solve(1.0, 2.0, lambda x: x**3 - x - 1)
phi3 = bisection_solve(1.0, 2.0, lambda x: x**4 - x - 1)
phi4 = bisection_solve(1.0, 2.0, lambda x: x**5 - x - 1)

f = lambda x: x**2 - x - 1
phi1_mead = nelder_mead_1D(lambda x: (f(x) if x >= 1 else x - 2)**2, 1.0, 1 + 2*epsilon)

def wegsteins_fixed_point(x1: float, g: Callable[[float], float]) -> float:
    # find a root x of f(x)
    x2 = g(x1)
    dx = 1.0
    while True:
        b = (x1 + g(x2) - x2 - g(x1))
        if b != 0:
            x3 = (x1 * g(x2) - x2 * g(x1)) / b
            dx = x3 - x2
        else:
            x3 = x2 + dx
        if x3 == x2:
            return x3
        x1 = x2
        x2 = x3

# TODO: n-dimensional optimization

# Complex, # https://mathworld.wolfram.com/ComplexExponentiation.html / complex instructions?
# Vector, Matrix?

# https://en.wikipedia.org/wiki/Category:Numerical_integration_(quadrature)
#     [-1, 1] https://en.wikipedia.org/wiki/Gauss–Legendre_quadrature
#    [0, inf) https://en.wikipedia.org/wiki/Gauss–Laguerre_quadrature
# (-inf, inf) https://en.wikipedia.org/wiki/Gauss–Hermite_quadrature
#      (a, b) https://en.wikipedia.org/wiki/Newton–Cotes_formulas
#     (-1, 1) https://en.wikipedia.org/wiki/Tanh-sinh_quadrature
#     (-1, 1) https://en.wikipedia.org/wiki/Gauss–Jacobi_quadrature
#     (-1, 1) https://en.wikipedia.org/wiki/Chebyshev–Gauss_quadrature
