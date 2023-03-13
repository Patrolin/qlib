from math import log, log2, log10
from math import remainder as rem, floor, ceil
import struct
from typing import Callable, TypeVar, cast

N = TypeVar("N", int, float)

def lerp(t: N, x: N, y: N) -> N:
    return x * (1-t) + y*t

def abs(x: N) -> N:
    return cast(N, x if (x > 0) else -x)

def sign(x: N) -> int:
    return (x > 0) - (x < 0)

# instrinsics
# a + b
# a - b
# a * b
# a / b
# a pow b
# a mod b
# a rem b

E = 2.718281828459045
TAU = 6.283185307179586
PI = TAU / 2

F64_EXPONENT_BITS = 11
F64_SIGNIFICAND_BITS = 52
F64_EXPONENT_MAX = 2**F64_EXPONENT_BITS - 1
F64_EXPONENT_MASK = F64_EXPONENT_MAX << F64_SIGNIFICAND_BITS
F64_EXPONENT_BIAS = F64_EXPONENT_MAX // 2
F64_EPSILON = 2.0**-F64_SIGNIFICAND_BITS
F64_ROUND_TO_INTEGER = 1.5 / F64_EPSILON

def fast_round(x: float) -> float: # accurate for x < 1000
    return x + F64_ROUND_TO_INTEGER - F64_ROUND_TO_INTEGER # disable fast math

def frexp(x: float) -> tuple[float, int]:
    i = _f64AsI64(x)
    exponent = ((i & F64_EXPONENT_MASK) >> F64_SIGNIFICAND_BITS) - F64_EXPONENT_BIAS
    i = i & ~F64_EXPONENT_MASK
    i |= F64_EXPONENT_BIAS << F64_SIGNIFICAND_BITS
    fraction = _i64AsF64(i)
    return fraction, exponent

def _f64AsI64(x: float):
    return struct.unpack("Q", struct.pack("d", x))[0]

def _i64AsF64(x: int):
    return struct.unpack("d", struct.pack("Q", x))[0]

F64_INF = _i64AsF64(F64_EXPONENT_MAX << F64_SIGNIFICAND_BITS)
F64_QNAN = _i64AsF64((-1 % 2**64) ^ (1 << (F64_SIGNIFICAND_BITS - 1)))
F64_SNAN = _i64AsF64(-1 % 2**64)
F64_INT_MAX = 2.0**(F64_SIGNIFICAND_BITS + 1)
F64_NORMAL_MAX = _i64AsF64(((F64_EXPONENT_MAX - 1) << F64_SIGNIFICAND_BITS) | (2**F64_SIGNIFICAND_BITS - 1))
F64_NORMAL_MIN = _i64AsF64(1 << F64_SIGNIFICAND_BITS)
F64_SUBNORMAL_MIN = _i64AsF64(1)

# TODO: quake invsqrt() # 0x5F375A82, 1.5008909 instead of 1.5??

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

if __name__ == "__main__":
    print(f"F64_INF: {F64_INF}")
    print(f"F64_QNAN: {F64_QNAN}")
    print(f"F64_SNAN: {F64_SNAN}")
    print(f"F64_INT_MAX: {F64_INT_MAX}")
    print(f"F64_NORMAL_MAX: {F64_NORMAL_MAX}")
    print(f"F64_NORMAL_MIN: {F64_NORMAL_MIN}")
    print(f"F64_SUBNORMAL_MIN: {F64_SUBNORMAL_MIN}")
