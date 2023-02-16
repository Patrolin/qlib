import struct
from typing import NamedTuple
from qlib.collections_ import findIndexOrDefault
from qlib.math_ import ceilLog10, log10, ceil, floor
from qlib.parsing import DIGITS
from qlib.parsing.parse_int import parseInt, printInt

class FloatBits(NamedTuple):
    exponent: int
    mantissa: int

def _bytes_count(floatBits: FloatBits) -> int:
    total_bits = (1 + floatBits.exponent + floatBits.mantissa)
    return total_bits//8 + ((total_bits % 8) > 0)

def _packFloat(acc: int, floatBits: FloatBits) -> float:
    PACK_FORMAT = "f" if _bytes_count(floatBits) <= 4 else "d"
    return struct.unpack(PACK_FORMAT, acc.to_bytes(_bytes_count(floatBits), "little"))[0]

def _unpackFloat(float_: float, floatBits: FloatBits) -> int:
    PACK_FORMAT = "f" if _bytes_count(floatBits) <= 4 else "d"
    UNPACK_FORMAT = "I" if _bytes_count(floatBits) <= 4 else "Q"
    return struct.unpack(UNPACK_FORMAT, struct.pack(PACK_FORMAT, float_))[0]

def _EXPONENT_MASK(floatBits: FloatBits) -> int:
    return (~(0xff_ff_ff_ff_ff_ff_ff_ff << floatBits.exponent)) & 0xff_ff_ff_ff_ff_ff_ff_ff

def _MANTISSA_MASK(floatBits: FloatBits) -> int:
    return (~(0xff_ff_ff_ff_ff_ff_ff_ff << floatBits.mantissa)) & 0xff_ff_ff_ff_ff_ff_ff_ff

def MAX_BASE10_SIGNIFICANT_DIGITS(floatBits: FloatBits) -> int:
    return 1 + ceil(floatBits.mantissa * log10(2))

def _MAX_EXPONENT(floatBits: FloatBits) -> int:
    return (1 << floatBits.exponent) - 1

FLOAT32 = FloatBits(8, 23)
FLOAT64 = FloatBits(11, 52)

# packed struct f32 { u1 sign, u8 exponent, u23 mantissa }
# exponent (zero/subnormal = 0, normal = 1..254, inf/NaN = 255), stored with bias of 127
# packed struct f64 { u1 sign, u11 exponent, u52 mantissa }
# exponent (zero/subnormal = 0, normal = 1..2046, inf/NaN = 2047), stored with bias of 1023

def parseFloat(s: str, floatBits: FloatBits) -> tuple[float, int]:
    i = 0
    MAX_EXPONENT = _MAX_EXPONENT(floatBits)
    HALF_MAX_EXPONENT = MAX_EXPONENT // 2

    acc = 0x00_00_00_00_00_00_00_00 # 64b
    # sign
    if i < len(s) and s[i] == "-":
        acc ^= 1 << (floatBits.exponent + floatBits.mantissa)
        i += 1

    # infinity
    if (i + 2 < len(s)) and s[i] == "i" and s[i + 1] == "n" and s[i + 2] == "f":
        i += 3
        acc = acc + (MAX_EXPONENT << floatBits.mantissa) # inf
        acc_float = _packFloat(acc, floatBits)
        return acc_float, i
    # TODO: parse NaN(..)?

    # integer
    exponent = 0
    mantissa = 0
    base10_digits = 0
    while True:
        if i >= len(s):
            break
        j = findIndexOrDefault(DIGITS[:10], lambda v: v == s[i])
        if j < 0:
            break
        i += 1
        if base10_digits < MAX_BASE10_SIGNIFICANT_DIGITS(floatBits):
            mantissa = mantissa*10 + j
            base10_digits += 1
    exponent_offset = max(mantissa.bit_length() - 1, 0)
    integer_offset = floatBits.mantissa - exponent_offset
    exponent += exponent_offset
    mantissa = mantissa << integer_offset

    # fraction
    fraction = 0
    if i < len(s) and s[i] == ".":
        i += 1
        while True:
            if i >= len(s):
                break
            j = findIndexOrDefault(DIGITS[:10], lambda v: v == s[i])
            if j < 0:
                break
            i += 1
            if base10_digits < MAX_BASE10_SIGNIFICANT_DIGITS(floatBits):
                fraction = fraction*10 + j
                base10_digits += 1
    divisor = 10**ceilLog10(fraction)
    while integer_offset > 0 and fraction > 0:
        fraction <<= 1
        bit = (fraction >= divisor)
        fraction -= bit * divisor
        if mantissa == 0: # find first non-zero bit
            exponent -= 1
        else: # fill in remaining bits
            integer_offset -= 1
        mantissa += bit << integer_offset
    mantissa += ((fraction << 1) >= divisor)

    # zero
    if mantissa == 0:
        exponent = -HALF_MAX_EXPONENT

    # base10 exponent
    if (i == 0) or ((i == 1) and s[0] == "-"):
        exponent = 0 # 1.0 by default
    acc = acc + ((exponent + HALF_MAX_EXPONENT) << floatBits.mantissa) + (mantissa & _MANTISSA_MASK(floatBits))
    acc_float = _packFloat(acc, floatBits)
    if i < len(s) and s[i] == "e":
        i += 1
        base10_exponent_sign = 1
        if i < len(s) and s[i] == "-":
            i += 1
            base10_exponent_sign = -1
        base10_exponent, j = parseInt(s[i:])
        if j > 0:
            i += j
            exponent_correction = base10_exponent_sign * base10_exponent
            if exponent_correction >= 0:
                acc_float *= 10.0**exponent_correction
            else:
                acc_float /= 10.0**(-exponent_correction)
        else:
            return acc_float, -i

    return acc_float, i

def parseFloat32(string: str):
    return parseFloat(string, FLOAT32)

def parseFloat64(string: str):
    return parseFloat(string, FLOAT64)

def printFloat(float_: float, floatBits: FloatBits, base10_significant_digits=2) -> str:
    # sign
    float_as_int = _unpackFloat(float_, floatBits)
    negative = float_as_int >> (floatBits.exponent + floatBits.mantissa)
    acc_string = "-" if negative else ""
    acc = -float_ if negative else float_
    if acc == 0.0: return acc_string + "0."

    # inf/NaN
    unsigned_exponent = (float_as_int >> floatBits.mantissa) & _EXPONENT_MASK(floatBits)
    if unsigned_exponent == _MAX_EXPONENT(floatBits):
        mantissa = float_as_int & _MANTISSA_MASK(floatBits)
        return acc_string + ("inf" if (mantissa == 0) else f"NaN(0b{printInt(mantissa, 2).zfill(floatBits.mantissa)})")

    # scientific notation
    base10_exponent = floor(log10(acc))
    base10_exponent_string = ""
    if (base10_exponent >= base10_significant_digits) or (base10_exponent <= -base10_significant_digits):
        acc = acc / (10**base10_exponent)
        base10_exponent_string = "e" + printInt(base10_exponent)

    # integer.fraction
    int_ = int(acc)
    acc_string += printInt(int_) + "."
    acc_fraction_string = ""
    nonzero_fraction = False
    for i in range((negative + (int_ == 0) + 1 + base10_significant_digits) - len(acc_string)):
        acc = (acc*10) % 10
        acc_fraction_string += DIGITS[int(acc)]
        nonzero_fraction |= int(acc) > 0
    if nonzero_fraction: acc_string += acc_fraction_string
    return acc_string + base10_exponent_string

def printFloat32(float_: float) -> str:
    return printFloat(float_, FLOAT32)

def printFloat64(float_: float) -> str:
    return printFloat(float_, FLOAT64)

if __name__ == "__main__": # TODO: move this to tests
    print(parseFloat32("inf")) # inf
    print(parseFloat32("-inf")) # -inf
    print(parseFloat32("1")) # 1.0
    print(parseFloat32("1.")) # 1.0
    print(parseFloat32("-1.0")) # -1.0
    print(parseFloat32("0")) # 0.0
    print(parseFloat32("0.")) # 0.0
    print(parseFloat32("-0.0")) # -0.0
    print(parseFloat32("e2")) # 100.0
    print(parseFloat32("-e-2")) # -0.01
    print(parseFloat32("1234")) # 1234.0
    print(parseFloat32("1.34")) # 1.3399999141693115
    print(parseFloat32("1.34e2")) # 133.99999141693115
    print(parseFloat32("0.3")) # 0.29999998211860657
    print(parseFloat32("-0.3")) # -0.29999998211860657
    print()

    print(parseFloat64("inf")) # inf
    print(parseFloat64("-inf")) # -inf
    print(parseFloat64("1")) # 1.0
    print(parseFloat64("1.")) # 1.0
    print(parseFloat64("-1.0")) # -1.0
    print(parseFloat64("0")) # 0.0
    print(parseFloat64("0.")) # 0.0
    print(parseFloat64("-0.0")) # -0.0
    print(parseFloat64("e2")) # 100.0
    print(parseFloat64("-e-2")) # -0.01
    print(parseFloat64("1234")) # 1234.0
    print(parseFloat64("1.34")) # 1.3399999999999999
    print(parseFloat64("1.34e2")) # 134
    print(parseFloat64("0.3")) # 0.3
    print(parseFloat64("-0.3")) # -0.3
    print()

    print(printFloat32(1.0)) # 1.
    print(printFloat32(-0.0)) # -0.
    print(printFloat32(123.4)) # 1.2e2
    print(printFloat32(0.375)) # 0.37
    print(printFloat32(-parseFloat32("inf")[0])) # -inf
    print(printFloat32(_packFloat(0x7f_80_00_01, FLOAT32))) # should be NaN(0b00000000000000000000001), but python is stupid
    print(printFloat32(_packFloat(0x7f_c0_00_01, FLOAT32))) # NaN(0b10000000000000000000001)
    print(printFloat32(_packFloat(0xff_ff_ff_ff, FLOAT32))) # -NaN(0b11111111111111111111111)
    print(printFloat32(0.375)) # 0.37
    print()

    print(printFloat64(0.0)) # 0.
    print(printFloat64(-0.0)) # -0.
    print(printFloat64(1.0)) # 1.
    print(printFloat64(1.2)) # 1.2
    print(printFloat64(12)) # 12.
    print(printFloat64(123.4)) # 1.2e2
    print(printFloat64(0.375)) # 0.37
    print(printFloat64(0.12345678901234566)) # 0.12
    print(printFloat64(-0.12345678901234566)) # -0.12
    print(printFloat64(1e2)) # 1.e2
    print(printFloat64(2e-2)) # 2.e-2
    print(printFloat64(-3e6)) # -3.e6
    print(printFloat64(-4e-6)) # -4.e-6
    print()

    print(printFloat(-1e-6, FLOAT32, base10_significant_digits=MAX_BASE10_SIGNIFICANT_DIGITS(FLOAT32))) # -0.00000100
    print(printFloat(-1e-6, FLOAT64, base10_significant_digits=MAX_BASE10_SIGNIFICANT_DIGITS(FLOAT64))) # -0.00000100000000000
