from math import isnan, prod
from pprint import pprint
from typing import Callable, Iterable, TypeVar
from qlib.math.float import F64_NORMAL_MIN, F64_QNAN, TAU, cos, lerp
from qlib.math.random import rand
from qlib.tests import assert_equals, assert_greater_than_equals, assert_is_close, assert_fail

# TODO: move to random
def phi(n: int) -> float:
    assert_greater_than_equals(n, 1)
    prev = 1
    x = 0
    while True:
        x = (1 + prev)**(1 / (n+1))
        if x == prev: return prev
        prev = x

def randList(s: float, n: int) -> list[float]:
    return [(s / phi(i + 1)) % 1 for i in range(n)]

# TODO: global n-dimensional optimization?

Node = TypeVar("Node")

def aStar(start: Node, neighbors: Callable[[Node], Iterable[Node]], goal: Callable[[Node], bool], heuristic: Callable[[Node],
                                                                                                                      float]) -> list[Node]:
    ... # TODO

# matrix determinant?
## (ax + by)*(cx + dy)
## = acxx + adxy + bcyx + bdyy
## = (ad - bc)xy
# matrix inverse
## A.inverse() = 1/A.det() * A.adjoint()
## A.adjoint() = (-1)^(i+j) A[i,j]

def raySolveNonlinear(X: list[float], f: Callable[[list[float]], float]):
    n = len(X)
    prev_X = X
    hitCount = 0
    i = 0
    while hitCount < 100:
        R = [1 - 2*v for v in randList(i, n)]
        # grow
        b = 1.0
        f_b = abs(f([X[i] + b * R[i] for i in range(n)]))
        if f_b < abs(f(X)):
            while True:
                f_next = abs(f([X[i] + 2 * b * R[i] for i in range(n)]))
                if f_next < f_b:
                    f_b = f_next
                    b *= 2
                else:
                    break
        # shrink
        a = 0.0
        f_a = abs(f([X[i] + a * R[i] for i in range(n)]))
        while True:
            m = (a+b) * .5
            if m == a or m == b: break
            f_m = abs(f([X[i] + m * R[i] for i in range(n)]))
            if f_m < f_a:
                f_a = f_m
                a = m
            else:
                f_b = f_m
                b = m
        f_a = abs(f([X[i] + a * R[i] for i in range(n)]))
        if f_a < f_b:
            X = [X[i] + a * R[i] for i in range(n)]
        else:
            X = [X[i] + b * R[i] for i in range(n)]
        X = [x if abs(x) >= F64_NORMAL_MIN else 0.0 for x in X]
        #print(X, abs(f(X)))
        if X == prev_X:
            hitCount += 1
        else:
            hitCount = 0
        prev_X = X
        i += 1
    return X

def raySolveNonlinearSystem(X: list[float], f: Callable[[list[float]], list[float]]):
    return raySolveNonlinear(X, lambda X0: sum(v**2 for v in f(X0)))

def solveLinearSystem(system: list[list[float]]):
    n = len(system)
    assert_equals(len(system[0]), n + 1)
    # normalize
    x = system[0][0]
    if x == 0.0: raise ValueError()
    k = 1.0 / x
    for column in range(n + 1):
        system[0][column] *= k
    for row in range(1, n):
        # subtract
        for row_under in range(row, n):
            k = system[row_under][row - 1]
            for column in range(n + 1):
                system[row_under][column] -= k * system[row - 1][column]
        # normalize
        x = system[row][row]
        if x == 0.0: raise ValueError("inf solutions")
        k = 1.0 / x
        for column in range(n + 1):
            system[row][column] *= k
    #pprint(system)
    for row in range(n - 1, 0, -1):
        # subtract
        for row_above in range(row):
            k = system[row_above][row]
            for column in range(row, n + 1):
                system[row_above][column] -= k * system[row][column]
        #pprint(system)
    #pprint(system)
    for row in range(n):
        for column in range(n):
            assert_is_close(system[row][column], 1.0 if (row == column) or (column == n + 1) else 0.0)
    return [system[row][n] for row in range(n)]

# TODO: https://hero.handmade.network/forums/game-discussion/t/3049-handmade_hero_day_440_-_introduction_to_function_approximation_with_andrew_bromage ~2ULP
# (inf/nan)
# (Cody & Waite Additive Range Reduction / Double Residue Modular Range Reduction / Payne & Hanek Reduction)
# chebshev polynomial (https://en.wikipedia.org/wiki/Remez_algorithm)
## a0 + a1x^1 + ... # solve system of equations for a_n, E
## find new extrema with golden section search
# horner's method

def polynomial(x: float, A: list[float]) -> float:
    acc_y = 0.0
    acc_x = 1.0
    for a in A:
        acc_y += acc_x * a
        acc_x *= x
    return acc_y

def chebyshevRoot(i: float, n: float) -> float:
    return 0.5 - 0.5 * cos((1 + 2*i) / (2*n) * TAU / 2)

def newtonFindNRoots(f: Callable[[float], float], n: int, acc_x=0.0, max_tries=10_000) -> list[float]:
    acc_roots = []

    def f1(x: float) -> float:
        acc_y = f(x)
        for root in acc_roots:
            acc_y /= (x - root)
        return acc_y

    for i in range(n):
        #print(f"roots = {acc_roots}")
        for j in range(max_tries):
            try:
                y1 = f1(acc_x)
                y2 = f1(acc_x + 1e-6)
                dy = (y2-y1) / 1e-6
                #print(f"{acc_x} .. ({y1}, {y2}), {dy}")
                if abs(y1) < 1e-13:
                    break
                if abs(dy) < 1e-6:
                    acc_x += 1 - 2 * rand()
                else:
                    acc_x -= y1 / dy
            except ZeroDivisionError:
                acc_x += 1 - 2 * rand()
        else:
            assert_fail(f"Reach max try count, roots={acc_roots}")
        acc_roots.append(acc_x)
    return acc_roots

def minimax(f: Callable[[float], float], start: float, end: float, d: int) -> list[float]:
    X = [lerp(chebyshevRoot(i, d + 1), start, end) for i in range(d + 1)]
    system = [[0.0] * (d+2) for i in range(d + 1)]
    print(f"X = {X}")
    while True:
        # fit polynomial
        for i, x in enumerate(X):
            for j in range(d):
                system[i][j] = x**j
        for i in range(d + 1):
            system[i][d] = (-1)**i
        for i, x in enumerate(X):
            system[i][d + 1] = f(x)
        #pprint(system)
        solve = solveLinearSystem(system)
        A = solve[:-1]
        E = solve[-1]

        def error(x: float) -> float:
            return f(x) - polynomial(x, A)

        print(f"A = {A}, E = {E}")
        error_roots = newtonFindNRoots(error, d)
        print(f"error_roots = {error_roots}")
        print(f"errors = {[error(x) for x in error_roots]}")

        # TODO: find roots of e(x) = f(x) - P(x) # (R2 + nearest root? (Wegstein's Method?))
        # TODO: find local extrema of e(x) between the roots (golden section search)
        # TODO: if X.every(x => e(x) == E), return
        if True:
            return A

if __name__ == "__main__":
    print(newtonFindNRoots(lambda x: x**2 - 1, 2)) # [-1.0, 1.0]
    print(newtonFindNRoots(lambda x: x**2 - x - 1, 2)) # [-0.6180339887498949, 1.6180339887498947]
    from math import sin # TODO: _slowSin by taylor series
    A = minimax(sin, 0.0, TAU / 4, 2)
    print(f"A(0.0): {polynomial(0.0, A)}")
    print(f"A(0.5): {polynomial(0.5, A)}")
    print(f"A(1.0): {polynomial(1.0, A)}")
    #print(solveLinearSystem([[1, 1, 1, 0], [1, 2, 3, 2], [1, 3, 2, 1]]))
