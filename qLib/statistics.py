from typing import overload, Optional
from .collections_ import *
from .math_ import *

# (sample mean, sample standard deviation)
@overload
def meanOrZero(X: list[int] | list[float]) -> float:
    ...

@overload
def meanOrZero(X: list[int] | list[float], weights: list[int] | list[float]) -> float:
    ...

def meanOrZero(X: list[int] | list[float], weights: Optional[list[int] | list[float]] = None):
    '''return the population mean = sample mean of X in O(n)'''
    if len(X) == 0: return 0
    if weights == None:
        acc = 0.0
        for x in X:
            acc += x
        return acc / len(X)
    else:
        acc = 0.0
        for i in range(len(X)):
            acc += X[i] * weights[i]
        return acc

def stdevOrZero(X: list[int] | list[float], u: float) -> float:
    '''return the sample standard deviation of X given the sample mean u in O(n)'''
    if len(X) == 1: return 0
    acc = 0.0
    for x in X:
        acc += (x - u)**2
    return (acc / (len(X) - 1))**0.5

# NTP stuff
def modeOrZero(X: list[int] | list[float]) -> float:
    '''return an estimated in-distribution mode of a sorted X in O(n)'''
    if len(X) == 0: return 0
    u = meanOrZero(X)
    A = LinkedList(X)
    for n in range(len(X) - 1, 0, -1):
        # remove farthest neighbor of the mean
        a, a_distance = A[0], abs(A[0] - u)
        b, b_distance = A[A.count - 1], abs(A[A.count - 1] - u)
        if a_distance >= b_distance:
            u -= (a-u) / n
            A.popLeft()
        else:
            u -= (b-u) / n
            A.pop()
    return A[0]
    # d > 1
    # https://stackoverflow.com/questions/59672100/how-to-find-farthest-neighbors-in-euclidean-space
    # http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.386.8193&rep=rep1&type=pdf
    # https://en.wikipedia.org/wiki/Priority_queue
    # https://en.wikipedia.org/wiki/R-tree
    # https://en.wikipedia.org/wiki/Ball_tree

# infinite streams
class EMA:
    def __init__(self, k=0.9):
        self.k = k
        self.x_old = 0.0

    def next(self, x: float) -> float:
        '''return the next EMA step in O(1)'''
        self.x_old = (1 - self.k) * x + self.k * self.x_old
        return self.x_old

if __name__ == '__main__':
    X = sorted([0, .24, .25, 1])
    print(modeOrZero(X), X)

    phi = (1 + 5**.5) / 2
    X = sorted([(0.5 + i*1/phi) % 1 for i in range(6)])
    print(modeOrZero(X), X)
    print(meanOrZero(X), stdevOrZero(X, meanOrZero(X)))
