from typing import Callable, Iterable, TypeVar
from qlib.math.float import F64_EPSILON, F64_NORMAL_MIN
from qlib.tests import assert_equals, assert_greater_than_equals

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

def raySolve(X: list[float], f: Callable[[list[float]], float]):
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
    return raySolve(X, lambda X0: sum(v**2 for v in f(X0)))

def solveLinearSystem(X: list[list[float]]):
    n = len(X)
    assert_equals(len(X[0]), n + 1)
    # normalize
    x = X[0][0]
    if x == 0.0: raise ValueError()
    k = 1 / x
    for column in range(n + 1):
        X[0][column] *= k
    for row in range(1, n):
        # subtract
        for row_under in range(row, n):
            k = X[row_under][row - 1]
            for column in range(n + 1):
                X[row_under][column] -= k * X[row - 1][column]
        # normalize
        x = X[row][row]
        if x == 0.0: raise ValueError()
        k = 1 / x
        for column in range(n + 1):
            X[row][column] *= k
    for row in range(n - 1, 0, -1):
        # subtract
        for row_above in range(row):
            k = X[row_above][row_above + 1]
            for column in range(row, n + 1):
                X[row_above][column] -= X[row][column]
    for row in range(n):
        for column in range(n):
            assert_equals(X[row][column], 1.0 if (row == column) or (column == n + 1) else 0.0)
    return [X[row][n] for row in range(n)]

# TODO: (Generalized Aitken-Steffensen / Steffensen's / Newton's / False position + invert matrix)?
# / (Secant / Generalized newton) + solve linear system?
# / grid search but bisection # random direction?

# TODO: https://hero.handmade.network/forums/game-discussion/t/3049-handmade_hero_day_440_-_introduction_to_function_approximation_with_andrew_bromage ~2ULP
# (inf/nan)
# (Cody & Waite Additive Range Reduction / Double Residue Modular Range Reduction / Payne & Hanek Reduction)
# chebshev polynomial (https://en.wikipedia.org/wiki/Remez_algorithm)
## a0 + a1x^1 + ... # solve system of equations for a_n, E
## find new extrema with golden section search
# horner's method
