from typing import Callable, Union
from qLib.serialize.serialize_int import parseInt
from .tests import assert_equals, assert_greater_than_equals, assert_less_than_equals, assert_never
from .math_ import reduce

_INT_BASE = 16
MAX_PRINT_BLADES = 2**16

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

    def parse_blade_normalized(s: str, i: int) -> tuple["Blade", int]:
        acc, i = parseInt(s, i) # TODO: signed int
        if i <= 0: acc = 1
        # TODO: str_value = parse_op()?
        acc_str = ""
        for v in s[1:]:
            acc_str += v
            i = len(acc_str) - 1
            while i > 0:
                if acc_str[i - 1] <= acc_str[i]: break
                acc *= -1
                tmp = acc_str[i] + acc_str[i - 1]
                acc_str = acc_str[:i - 1] + tmp + acc_str[i + 1:]
                i -= 1
            if i - 1 >= 0 and acc_str[i] == acc_str[i - 1]:
                acc *= bases[int(acc_str[i], _INT_BASE) - min_basis]
                acc_str = acc_str[:i - 1] + acc_str[i + 1:]
        return Blade(acc, "", f"e{acc_str}" if acc_str else "1"), len(s)

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
        normalized_unit, i = parse_blade_normalized(unit.name, 0)
        assert_greater_than_equals(i, 1)
        return Blade(normalized_blade.value * normalized_unit.value, normalized_blade.str_value, unit.name)

    def dual(blade: "Blade", key: Callable[["Blade"], "Blade"]):
        missigned_dual = mask_to_unit[bladeMask(blade.name) ^ bladeMask(pseudoscalar.name)]
        product = key(missigned_dual)
        assert_equals(abs(product.value), 1)
        assert_equals(product.name, pseudoscalar.name)
        sign_correction = 1 - 2 * (product.value == -1)
        return Blade(blade.value * missigned_dual.value * sign_correction, blade.str_value, missigned_dual.name)

    class Blade:
        def __init__(self, value: Union[int, float], str_value: str, name: str):
            if value == -0.0: value = 0
            self.value = value
            self.str_value = str_value
            self.name = name if value != 0 else "1"

        def __repr__(self):
            return f"{self.value}{self.str_value}{self.name if self.name != '1' else ''}"

        def __eq__(self, other: "Blade"):
            return (self.value == other.value) and (self.str_value == other.str_value) and (self.name == other.name)

        def grade(self):
            return len(self.name) - 1

        def gradeSelect(self, n: int):
            return self * (self.grade() == n)

        def __invert__(self):
            sign = 1 - 2 * ((self.grade() // 2) % 2)
            return self * sign

        def __neg__(self):
            return self * -1

        def dual(self) -> "Blade": # right complement
            return dual(self, lambda v: Blade(1, "", self.name) * v)

        def undual(self) -> "Blade": # left complement
            return dual(self, lambda v: v * Blade(1, "", self.name))

        def __add__(self, other: "Blade") -> "Blade":
            assert_equals(self.str_value, other.str_value)
            assert_equals(self.name, other.name)
            return Blade(self.value + other.value, self.str_value, self.name)

        def __sub__(self, other: "Blade") -> "Blade":
            assert_equals(self.str_value, other.str_value)
            assert_equals(self.name, other.name)
            return Blade(self.value - other.value, self.str_value, self.name)

        def __mul__(self, other: Union[int, float, "Blade"]) -> "Blade":
            if isinstance(other, Blade):
                normalized_blade, i = parse_blade_normalized(f"e{self.name[1:]}{other.name[1:]}", 0)
                assert_greater_than_equals(i, 0)
                normalized_blade.value *= self.value * other.value
                normalized_blade.str_value = self.str_value + other.str_value
                return denormalize_blade(normalized_blade)
            else:
                return Blade(self.value * other, self.str_value, self.name)

        def __rmul__(self, other: Union[int, float]):
            return self * other

        def __truediv__(self, other: Union[int, float]):
            return self * (1/other)

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

        def commutator(self, other: Union["Blade", int, float]):
            if isinstance(other, Blade):
                return (self*other - other*self) / 2
            else:
                return self.commutator(Blade(other, "", "1"))

    for str_blade in str_blades:
        blade = Blade(1, "", str_blade)
        mask_to_unit[bladeMask(str_blade)] = blade
        blades.append(blade)
    pseudoscalar = blades[-1]
    assert_equals(len(mask_to_unit), blade_count)

    class Multivector:
        values: list[Blade] = []

        def add(self, blade: Blade):
            for v in self.values:
                if (v.str_value == blade.str_value) and (v.name == blade.name):
                    v.value += blade.value
                    return
            self.values.append(blade)

    class GAlgebra:
        name = generic_name = f"G_{positive},{negative},{zero}"
        blades: list[Blade]

        @staticmethod
        def parse_blade(s: str, i: int) -> tuple[Blade, int]:
            blade, i = parse_blade_normalized(s, i)
            return denormalize_blade(blade), i

        @staticmethod
        def parse_multivector(s: str, i: int) -> tuple[Multivector, int]:
            acc = Multivector()
            i = (s[0] == "(")
            while i < len(s):
                blade, j = parse_blade_normalized(s, i)
                if j <= i: break
                acc.add(blade)
                i = j
                # TODO: whitespace
                if i < len(s) and s[i] == "+": i += 1
                # TODO: whitespace
            return acc, i

        @staticmethod
        def print_generic_name():
            print(f"-- {GAlgebra.generic_name}")

        @staticmethod
        def print_name():
            print(f"-- {GAlgebra.name}")

        @staticmethod
        def print_row(f: Callable[[Blade], Blade]):
            assert_less_than_equals(blade_count, MAX_PRINT_BLADES)
            print("".join(str(f(v)).rjust(log_blade_count + 6, " ") for v in GAlgebra.blades))

        @staticmethod
        def print_table(f: Callable[[Blade, Blade], Blade]):
            assert_less_than_equals(blade_count**2, MAX_PRINT_BLADES)
            for a in blades:
                GAlgebra.print_row(lambda b: f(a, b))

        @staticmethod
        def assert_equals(f: Callable[[Blade, Blade], Blade], g: Callable[[Blade, Blade], Blade]):
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
CONIC_ALGEBRA = GAlgebra(5, 3, 0)
QUADRIC_ALGEBRA = GAlgebra(9, 6, 0)
VGA_2D = GAlgebra(2, 0, 0)
VGA_3D = GAlgebra(3, 0, 0)
PGA_2D = GAlgebra(2, 0, 1, start_with_zero=True, signs=["e20"])
PGA_3D = GAlgebra(3, 0, 1, start_with_zero=True, signs=["e31", "e021", "e032"])
CGA_2D = GAlgebra(3, 1, 0)
CGA_3D = GAlgebra(4, 1, 0)
