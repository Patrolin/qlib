from typing import Callable, Union
from qLib.collections_ import findIndexOrDefault, reduce
from qLib.parsing.parse_float import parseFloat64
from qLib.parsing.parse_int import parseInt
from qLib.parsing.parse_math import parseMath, parseOp, parseTokens
from .tests import assert_, assert_equals, assert_greater_than_equals, assert_less_than_equals, assert_never

_INT_BASE = 10
MAX_PRINT_BLADES = 2**16

def _signedJoin(arr: list[str]) -> str:
    def _print_item(i: int, str_item: str):
        sign = "-" if str_item.startswith("-") else ""
        if (i > 0): sign = " - " if (sign == "-") else " + "
        return f"{sign}{str_item.removeprefix('-')}"

    return f"({''.join(_print_item(i, v) for i, v in enumerate(arr))})"

class Coefficient:
    number: int | float
    product: list[str]

    def __init__(self, number: int | float, product: list[str]):
        self.number = int(number) if isinstance(number, float) and number.is_integer() else number
        self.product = product

    def __eq__(self, other: Union[int, float, "Coefficient"]):
        if isinstance(other, Coefficient):
            return (self.number == other.number) and (self.product == other.product)
        else:
            return (self.number == other) and (len(self.product) == 0)

    def __repr__(self):
        str_number = repr(self.number)
        if len(self.product) == 0: return str_number
        if (abs(self.number) == 1):
            str_number = ("" if self.number == 1 else "-")
        if len(self.product) == 1: return f"{str_number}{self.product[0]}"
        else: return f"{str_number}({'*'.join(self.product)})"

    def _mul(self, other: str):
        i = 0
        for i in range(len(self.product)):
            if self.product[i] >= other: break
        else:
            i = len(self.product)
        self.product.insert(i, other)

    def __mul__(self, other: "Coefficient"):
        acc = Coefficient(self.number * other.number, self.product.copy())
        for v in other.product:
            acc._mul(v)
        return acc

class Value:
    sum: list[Coefficient]

    def __init__(self, sum: list[Coefficient]):
        self.sum = sum

    def __eq__(self, other: Union[int, float, "Value"]):
        if isinstance(other, Value):
            return self.sum == other.sum
        else:
            return ((len(self.sum) == 1) and (self.sum[0] == other)) if (other != 0) else (len(self.sum) == 0)

    def __repr__(self):
        if len(self.sum) == 0: return "0"
        elif len(self.sum) == 1: return repr(self.sum[0])
        else: return _signedJoin([repr(v) for v in self.sum])

    def _deep_copy(self):
        return Value([Coefficient(v.number, v.product.copy()) for v in self.sum])

    def _add(self, other: "Coefficient"):
        if other.number == 0: return
        for i in range(len(self.sum)):
            if self.sum[i].product == other.product:
                self.sum[i].number += other.number
                if self.sum[i].number == 0: self.sum.pop(i)
                return
        i = sum(1 for v in self.sum if other.product > v.product)
        self.sum.insert(i, other)

    @staticmethod
    def fromNumber(number: int | float):
        acc = Value([])
        acc._add(Coefficient(number, []))
        return acc

    def __add__(self, other: "Value"):
        acc = self._deep_copy()
        for v in other.sum:
            acc._add(v)
        return acc

    def __sub__(self, other: "Value"):
        return self + Value([Coefficient(-v.number, v.product.copy()) for v in other.sum])

    def __mul__(self, other: "Value"):
        acc = Value.fromNumber(0)
        for a in self.sum:
            for b in other.sum:
                acc._add(a * b)
        return acc

    def sqrt(self):
        return Value([Coefficient(1, [f"sqrt({self})"])])

def GAlgebra(positive: int, negative=0, zero=0, start_with_zero=False, signs: list[str] = []):
    bases: list[int] = []
    min_basis = 1
    if zero > 0 and start_with_zero:
        bases.append(0)
        min_basis = 0
    for v in range(positive):
        bases.append(1)
    for v in range(negative):
        bases.append(-1)
    for v in range(zero - start_with_zero):
        bases.append(0)
    log_blade_count = positive + negative + zero
    blade_count = 2**(positive + negative + zero)
    assert_less_than_equals(log_blade_count, _INT_BASE)

    def parse_blade_normalized(s: str, i=0) -> tuple["Blade", int]:
        k = findIndexOrDefault(s[i:], lambda v: v != "e", len(s))
        acc, j = parseFloat64(s[:i + k], i)
        if j == i: acc = 1
        i = j
        acc_str = ""
        if i < len(s) and s[i] == "e":
            i += 1
            j = parseInt(s, i, base=_INT_BASE)[1]
            if j > i:
                for v in s[i:j]:
                    acc_str += v
                    k = len(acc_str) - 1
                    while k > 0:
                        if acc_str[k - 1] <= acc_str[k]: break
                        acc *= -1
                        tmp = acc_str[k] + acc_str[k - 1]
                        acc_str = acc_str[:k - 1] + tmp + acc_str[k + 1:]
                        k -= 1
                    if k - 1 >= 0 and acc_str[k] == acc_str[k - 1]:
                        acc *= bases[int(acc_str[k], _INT_BASE) - min_basis]
                        acc_str = acc_str[:k - 1] + acc_str[k + 1:]
                i = j
        return Blade(Value.fromNumber(acc), f"e{acc_str}" if acc_str else "1"), i

    def genBlades():
        acc: list[str] = []
        for i in range(0, 2**len(bases)):
            str_bases = "".join(f"{j+min_basis:x}" for (j, v) in enumerate(bases) if (1 << j) & i) # TODO: support higher bases?
            str_blade = f"e{str_bases}" if len(str_bases) > 0 else "1"
            acc.append(str_blade)
        return sorted(acc, key=lambda v: (len(v), v))

    str_blades = genBlades()
    blades: list["Blade"] = []
    pseudoscalar: "Blade"
    mask_to_normalized_name: dict[int, str] = {}
    mask_to_unit: dict[int, "Blade"] = {}

    def bladeMask(name: str) -> int:
        return reduce(name[1:], lambda acc, v: acc ^ (1 << int(v, _INT_BASE)), 0)

    for override in signs:
        for i, str_blade in enumerate(str_blades):
            if bladeMask(override) == bladeMask(str_blade):
                str_blades[i] = override
                break
        else:
            assert_never(f"Unknown blade {override}")

    def denormalize_blade(normalized_blade: "Blade") -> "Blade":
        unit = mask_to_unit[bladeMask(normalized_blade.name)]
        normalized_unit, i = parse_blade_normalized(unit.name)
        assert_greater_than_equals(i, 1)
        return Blade(normalized_blade.value * normalized_unit.value, unit.name)

    def dual(blade: "Blade", key: Callable[["Blade"], "Blade"]):
        missigned_dual = mask_to_unit[bladeMask(blade.name) ^ bladeMask(pseudoscalar.name)]
        product = key(missigned_dual)
        assert_((product.value == 1) or (product.value == -1))
        assert_equals(product.name, pseudoscalar.name)
        sign_correction = 1 - 2 * (product.value == -1)
        return Blade(blade.value * missigned_dual.value * Value.fromNumber(sign_correction), missigned_dual.name)

    class Blade:
        def __init__(self, value: Value, name: str):
            self.value = value
            self.name = name if value != 0 else "1"

        @staticmethod
        def fromNumber(number: int | float):
            return Blade(Value.fromNumber(number), "1")

        def __repr__(self):
            str_value = repr(self.value)
            str_name = "" if (self.name == "1") else self.name
            if (str_value == "1") and (str_name != ""): str_value = ""
            if (str_value == "-1") and (str_name != ""): str_value = "-"
            return f"{str_value}{str_name}"

        def __eq__(self, other: "Blade"):
            return (self.name == other.name) and (self.value == other.value)

        def _deep_copy(self):
            return Blade(self.value._deep_copy(), self.name)

        def grade(self):
            return len(self.name) - 1

        def gradeSelect(self, n: int):
            return self * Value.fromNumber(int(self.grade() == n))

        def __invert__(self): # reverse
            sign = 1 - 2 * ((self.grade() // 2) % 2)
            return self * Value.fromNumber(sign)

        def __neg__(self):
            return self * Value.fromNumber(-1)

        def dual(self) -> "Blade": # right complement
            return dual(self, lambda v: Blade(Value.fromNumber(1), self.name) * v)

        def undual(self) -> "Blade": # left complement
            return dual(self, lambda v: v * Blade(Value.fromNumber(1), self.name))

        def __add__(self, other: "Blade") -> "Blade":
            assert_equals(self.name, other.name)
            return Blade(self.value + other.value, self.name)

        def __sub__(self, other: "Blade") -> "Blade":
            assert_equals(self.name, other.name)
            return Blade(self.value - other.value, self.name)

        def __mul__(self, other: Union[Value, "Blade"]) -> "Blade":
            if isinstance(other, Blade):
                normalized_blade, i = parse_blade_normalized(f"e{self.name[1:]}{other.name[1:]}")
                assert_greater_than_equals(i, 0)
                normalized_blade.value *= self.value * other.value
                return denormalize_blade(normalized_blade)
            else:
                return Blade(self.value * other, self.name)

        def __rmul__(self, other: Value):
            return self * other

        def dot(self, other: "Blade"):
            return (self * other).gradeSelect(0).value

        def inner(self, other: "Blade"):
            return (self * other).gradeSelect(abs(self.grade() - other.grade()))

        def left_contraction(self, other: "Blade"):
            return (self * other).gradeSelect(other.grade() - self.grade())

        def __xor__(self, other: "Blade"): # wedge product
            return (self * other).gradeSelect(self.grade() + other.grade())

        def __and__(self, other: "Blade"): # antiwedge (regressive) product
            return (self.dual() ^ other.dual()).undual()

        def commutator(self, other: Union[Value, "Blade"]):
            if isinstance(other, Blade):
                return (self*other - other*self) * Value.fromNumber(0.5)
            else:
                return self.commutator(Blade(other, "1"))

    for str_blade in str_blades:
        blade = Blade(Value.fromNumber(1), str_blade)
        mask_to_normalized_name[bladeMask(str_blade)] = parse_blade_normalized(str_blade)[0].name
        mask_to_unit[bladeMask(str_blade)] = blade
        blades.append(blade)
    pseudoscalar = blades[-1]
    assert_equals(len(mask_to_unit), blade_count)

    class Multivector:
        blades: list[Blade]
        denominator: Value

        def __init__(self, blades: list[Blade] | None = None, denominator: Value | None = None):
            self.blades = blades or []
            self.denominator = denominator or Value.fromNumber(1)

        def __eq__(self, other: "Multivector"):
            return (self.blades == other.blades) and (self.denominator == other.denominator)

        def __repr__(self):
            if len(self.blades) == 0: return "0"
            str_blades = _signedJoin([repr(v) for v in self.blades])
            str_denom = "" if (self.denominator == 1) else f" / {self.denominator}"
            return f"{str_blades}{str_denom}"

        def _add(self, blade: Blade):
            if blade.value == 0: return
            i = 0
            for i in range(len(self.blades)):
                if (self.blades[i].name == blade.name):
                    self.blades[i].value += blade.value
                    if self.blades[i].value == 0: self.blades.pop(i)
                    return
            i = sum(1 for v in self.blades if mask_to_normalized_name[bladeMask(blade.name)] > mask_to_normalized_name[bladeMask(v.name)])
            self.blades.insert(i, blade)

        def __add__(self, other: "Multivector"):
            assert_equals(self.denominator, other.denominator) # TODO: multiply fraction?
            acc = Multivector()
            acc.blades = [v._deep_copy() for v in self.blades]
            for blade in other.blades:
                acc._add(blade)
            return acc

        def __neg__(self):
            return Multivector([-v for v in self.blades], self.denominator._deep_copy())

        def __sub__(self, other: "Multivector"):
            return self + (-other)

        def _map(self, key: Callable[[Blade], Blade]):
            acc = Multivector()
            for v in self.blades:
                acc._add(key(v))
            return acc

        def __invert__(self): # reverse
            return self._map(lambda v: ~v)

        def inverse(self):
            return ~self * Multivector([Blade.fromNumber(1)], self.pnorm_squared())

        def dual(self): # right complement
            return self._map(lambda v: v.dual())

        def undual(self): # left complement
            return self._map(lambda v: v.undual())

        # point based PGA dnorm
        def dnorm_squared(self) -> Value:
            return reduce((v.value * v.value for v in self.blades if (v * v).value == 0), lambda a, v: a + v, Value.fromNumber(0))

        def dnorm(self) -> Value:
            return self.dnorm_squared().sqrt()

        def dnormalized(self):
            return self * Multivector([Blade.fromNumber(1)], self.dnorm())

        # point based PGA pnorm
        def pnorm_squared(self):
            return reduce((v.value * v.value for v in self.blades if (v * v).value != 0), lambda a, v: a + v, Value.fromNumber(0))

        def pnorm(self) -> Value:
            return self.pnorm_squared().sqrt()

        def pnormalized(self):
            return self * Multivector([Blade(Value.fromNumber(1), "1")], self.pnorm())

        # point based PGA direction/position
        def direction(self):
            return self._map(lambda v: v * Blade.fromNumber(int("0" in v.name)))

        def position(self):
            return self._map(lambda v: v * Blade.fromNumber(int("0" not in v.name)))

        def _starmap(self, other: "Multivector", key: Callable[[Blade, Blade], Blade]):
            acc = Multivector()
            for a in self.blades:
                for b in other.blades:
                    acc._add(key(a, b))
            acc.denominator = self.denominator * other.denominator
            return acc

        def __mul__(self, other: "Multivector"):
            return self._starmap(other, lambda a, b: a * b)

        def dot(self, other: "Multivector"):
            return self._starmap(other, lambda a, b: Blade(a.dot(b), "1"))

        def inner(self, other: "Multivector"):
            return self._starmap(other, lambda a, b: a.inner(b))

        def left_contraction(self, other: "Multivector"):
            return self._starmap(other, lambda a, b: a.left_contraction(b))

        def __xor__(self, other: "Multivector"): # wedge product
            return self._starmap(other, lambda a, b: a ^ b)

        def __and__(self, other: "Multivector"): # antiwedge (regressive) product
            return self._starmap(other, lambda a, b: a & b)

        def commutator(self, other: "Multivector"):
            return self._starmap(other, lambda a, b: a.commutator(b))

    class GAlgebra:
        name = generic_name = f"G_{positive},{negative},{zero}"
        blades: list[Blade]

        @staticmethod
        def parse_blade(s: str) -> tuple[Blade, int]:
            blade, i = parse_blade_normalized(s)
            return denormalize_blade(blade), i

        @staticmethod
        def parse_multivector(s: str, i=0) -> tuple[Multivector, int]:
            acc = Multivector()
            math = parseMath(s, i)
            # TODO
            return acc, i

        @staticmethod
        def print_generic_name():
            print(f"-- {GAlgebra.generic_name}")

        @staticmethod
        def print_name():
            print(f"-- {GAlgebra.name}")

        @staticmethod
        def tprint_row(f: Callable[[Blade], Blade]):
            assert_less_than_equals(blade_count, MAX_PRINT_BLADES)
            return "".join(str(f(v)).rjust(log_blade_count + 6, " ") for v in GAlgebra.blades)

        @staticmethod
        def tprint_table(f: Callable[[Blade, Blade], Blade]):
            assert_less_than_equals(blade_count**2, MAX_PRINT_BLADES)
            return "\n".join(GAlgebra.tprint_row(lambda b: f(a, b)) for a in blades)

        @staticmethod
        def assert_functions_match(f: Callable[[Blade, Blade], Blade], g: Callable[[Blade, Blade], Blade]):
            for a in blades:
                for b in blades:
                    assert_equals(f(a, b), g(a, b))

    GAlgebra.blades = blades

    if (positive, negative, zero) == (1, 0, 0):
        GAlgebra.name = f"Hyperbolic numbers"
    elif (positive, negative, zero) == (0, 1, 0):
        GAlgebra.name = f"Complex numbers"
    elif (positive, negative, zero) == (0, 0, 1):
        GAlgebra.name = f"Dual numbers"
    elif (positive, negative, zero) == (5, 3, 0):
        GAlgebra.name = f"Conic Algebra"
    elif (positive, negative, zero) == (9, 6, 0):
        GAlgebra.name = f"Quadric Algebra"
    elif negative == 0 and zero == 0:
        GAlgebra.name = f"{positive}D Vector Algebra"
    elif negative == 0 and zero == 1:
        GAlgebra.name = f"{positive}D Projective Algebra"
    elif negative == 1 and zero == 0:
        GAlgebra.name = f"{positive-1}D Conformal Algebra"

    return GAlgebra

HYPERBOLIC_NUMBERS = GAlgebra(1, 0, 0)
COMPLEX_NUMBERS = GAlgebra(0, 1, 0)
DUAL_NUMBERS = GAlgebra(0, 0, 1)
#CONIC_ALGEBRA = GAlgebra(5, 3, 0)
#QUADRIC_ALGEBRA = GAlgebra(9, 6, 0)
VGA_2D = GAlgebra(2, 0, 0)
VGA_3D = GAlgebra(3, 0, 0)
PGA_2D = GAlgebra(2, 0, 1, start_with_zero=True, signs=["e20"])
PGA_3D = GAlgebra(3, 0, 1, start_with_zero=True, signs=["e31", "e021", "e032"])
PGA_4D = GAlgebra(4, 0, 1, start_with_zero=True)
CGA_2D = GAlgebra(3, 1, 0)
CGA_3D = GAlgebra(4, 1, 0)

def infPoint2D(x: float | str, y: float | str):
    return PGA_2D.parse_multivector(f"{x}e1+{y}e2")[0]

def point2D(x: float | str, y: float | str):
    return PGA_2D.parse_multivector(f"e0+{x}e1+{y}e2")[0]

def infPoint3D(x: float | str, y: float | str, z: float | str):
    return PGA_3D.parse_multivector(f"{x}e1+{y}e2+{z}e3")[0]

def point3D(x: float | str, y: float | str, z: float | str):
    return PGA_3D.parse_multivector(f"e0+{x}e1+{y}e2+{z}e3")[0]
