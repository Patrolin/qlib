from typing import Union

from qLib.collections_ import findIndex
from .tests import assert_equals, assert_, assert_not_equals
from .math_ import sign, reduce

def gMask(e: str) -> int:
    return reduce(e[1:], lambda acc, v: acc | (1 << int(v)), 0)

def gMultiply(bases: list[int], blades: list[str], a: str, b: str) -> str:
    for base in bases:
        assert_((base == 1) or (base == 0) or (base == -1))
    assert_(not a.startswith("-"))
    assert_(not a.startswith("-"))

    def gMultiply_(bases: list[int], a: str, b: str) -> tuple[str, int]:
        if a == "0" or b == "0": return "0", 0
        acc_str = ""
        acc = 1

        for blade in (a, b):
            for v in blade[1:]:
                acc_str += v
                i = len(acc_str) - 1
                while i > 0:
                    if acc_str[i - 1] <= acc_str[i]: break
                    acc *= -1
                    tmp = acc_str[i] + acc_str[i - 1]
                    acc_str = acc_str[:i - 1] + tmp + acc_str[i + 1:]
                    i -= 1
                if i - 1 >= 0 and acc_str[i] == acc_str[i - 1]:
                    acc *= bases[int(acc_str[i])]
                    acc_str = acc_str[:i - 1] + acc_str[i + 1:]
        return f"e{acc_str}" if acc_str else "1", acc

    acc_str, acc = gMultiply_(bases, a, b)
    mask = gMask(acc_str)
    i = findIndex(blades, lambda v: gMask(v) == mask)
    blade = blades[i]
    acc *= sign(gMultiply_(bases, blade, "1")[1])

    if acc == 0: return "0"
    sign_ = "-" if acc == -1 else ""
    return f"{sign_}{blade}"

def GAlgebra(str_mul_table: list[list[str]]):
    str_blades = str_mul_table[0]
    assert_equals(str_blades[0], "1")
    for v in str_blades:
        assert_not_equals(v[0], "-")
    str_vector = [v for v in str_blades if len(v) == 2]
    dummy_bases = [1 for v in str_vector]
    str_pseudoscalar = "e" + "".join(v[1] for v in str_vector)
    mul_table: list[list["GBlade"]] = []

    class GBlade:
        def __init__(self, index_: int, value: Union[int, float]):
            index = index_ if value != 0.0 else 0
            self.value = int(value) if isinstance(value, float) and value.is_integer() else value
            self.index = index

        def __repr__(self):
            return f"{self.value}{str_blades[self.index] if self.index > 0 else ''}"

        # sum = A+B, A-B
        def __add__(self, other: "GBlade"):
            assert_equals(self.index, other.index)
            return GBlade(self.index, self.value + other.value)

        def __sub__(self, other: "GBlade"):
            assert_equals(self.index, other.index)
            return GBlade(self.index, self.value - other.value)

        # A^\dagger = reverse = ~A
        def __invert__(self):
            acc = 1
            for i in range(2, len(str_blades[self.index]), 2):
                acc *= -1
            return GBlade(self.index, self.value * acc)

        def involute(self):
            str_blade = str_blades[self.index]
            sign = (-1)**(len(str_blade) - 1)
            return self * sign

        # \overline{A} = A.conjugate()
        def conjugate(self):
            return (~self).involute()

        # hodge dual = I/A = A.dual()
        def dual(self):
            str_blade = str_blades[self.index]
            dual_mask = gMask(str_pseudoscalar) ^ gMask(str_blade)
            dual_index = findIndex(str_mul_table[0], lambda v: gMask(v) == dual_mask)
            str_dual = str_mul_table[0][dual_index]
            sign = -1 if gMultiply(dummy_bases, str_blades, str_dual, str_blade).startswith("-") else 1
            return GBlade(dual_index, self.value * sign)

        # grade selection
        def grade(self):
            return len(str_blades[self.index]) - 1

        def gradeSelect(self, n: int):
            return GBlade(self.index, self.value) if self.grade() == n else GBlade(0, 0)

        # geometric product = A*B
        def __mul__(self, other: Union["GBlade", int, float]):
            if isinstance(other, GBlade):
                v = mul_table[self.index][other.index]
                return GBlade(v.index, v.value * self.value * other.value)
            else:
                return GBlade(self.index, self.value * other)

        def __rmul__(self, other: Union[int, float]):
            return self * other

        def __truediv__(self, other: Union[int, float]):
            return self * (1/other)

        # dot product = A@B
        def __matmul__(self, other: "GBlade") -> float:
            return (self * other).gradeSelect(0).value

        # wedge product = A&B = (A.dual() | B.dual()).dual()
        def __and__(self, other: "GBlade"):
            return (self * other).gradeSelect(self.grade() + other.grade())

        # antiwedge (regressive) product = A|B = (A.dual() & B.dual()).dual()
        def __or__(self, other: "GBlade"):
            return (self.dual() & other.dual()).dual()

        # commutator product = A^B
        def __xor__(self, other: Union["GBlade", int, float]):
            if isinstance(other, GBlade):
                return (self*other - other*self) / 2
            else:
                return self ^ GBlade(0, other)

        # todo: wedge, antiwedge

    class GMultivector:
        pass

    class GAlgebra:
        blades: list[GBlade] = []

        @staticmethod
        def parse_blade(s: str, i: int) -> tuple[GBlade, int]:
            value_sign = 1
            while i < len(s) and s[i] == "-":
                value_sign *= -1
                i += 1
            j = i
            while j < len(s) and s[j].isnumeric():
                j += 1
            continued = j < len(s) and s[j] == "e"
            value = int(s[i:j] or 1 if continued else s[i:j]) * value_sign
            i = j
            while j < len(s) and s[j] != " ":
                j += 1
            index = str_blades.index(s[i:j]) if j != i else 0
            return GBlade(index, value), j

        @staticmethod
        def parse_multivector(s: str, i: int) -> tuple[GMultivector, int]:
            pass

    mul_table = [[GAlgebra.parse_blade(v, 0)[0] for v in row] for row in str_mul_table]
    unique_blades = set(v.index for v in mul_table[0])
    assert_equals(len(str_blades), len(unique_blades))
    assert_equals(len(str_blades), len(mul_table))

    GAlgebra.blades = [GAlgebra.parse_blade(v, 0)[0] for v in str_blades]

    return GAlgebra

def mul_table(bases: list[int], blades: list[str]):
    return [[gMultiply(bases, blades, v, w) for w in blades] for v in blades]

PGA_2D = GAlgebra(mul_table([0, 1, 1], ["1", "e0", "e1", "e2", "e01", "e20", "e12", "e012"]))

# Todo: PGA_2D.expand("(v1+v2e0) * (v1+v2e0)") # left and right must already be expanded
# PGA_2D.expand("(v1+v2e0) *~ (v1+v2e0)")
# PGA_2D.expand("ae20 sandwich b") == PGA_2D.expand(f"{PGA_2D.expand("b * ae20")} *~ b")
# PGA_2D.expand("-9.8e20 sandwich (1)")
