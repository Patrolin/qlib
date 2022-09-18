from .tests import assert_equals, assert_
from .math_ import sign, reduce

def GAlgebra(mul_table_str: list[list[str]]):
    blades = mul_table_str[0]
    assert_equals(blades[0], "1")
    mul_table: list[list["GBlade"]] = []

    class GBlade:
        def __init__(self, index: int, value: float):
            self.value = value
            self.index = index

        def __add__(self, other: "GBlade"):
            assert_equals(self.index, other.index)
            return GBlade(self.index, self.value + other.value)

        def __mul__(self, other: "GBlade"):
            v = mul_table[self.index][other.index]
            return GBlade(v.index, v.value * self.value * other.value)

        def __repr__(self):
            return f"{self.value}{blades[self.index] if self.index > 0 else ''}"

    class GMultivector:
        pass

    class GAlgebra:
        @staticmethod
        def parse_blade(s: str, i: int) -> tuple[int, GBlade]:
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
            index = blades.index(s[i:j]) if j != i else 0
            return j, GBlade(index, value)

        @staticmethod
        def parse_multivector(s: str, i: int) -> tuple[int, GMultivector]:
            pass

    mul_table = [[GAlgebra.parse_blade(v, 0)[1] for v in row] for row in mul_table_str]
    unique_blades = set(v.index for v in mul_table[0])
    assert_equals(len(blades), len(unique_blades))
    assert_equals(len(blades), len(mul_table))

    return GAlgebra

def mul_table(bases: list[int], blades: list[str]):
    for base in bases:
        assert_((base == 1) or (base == 0) or (base == -1))

    def gMask(e: str) -> int:
        return reduce(e[1:], lambda acc, v: acc | (1 << int(v)), 0)

    blade_masks = [gMask(v) for v in blades]

    def gMultiply_(a: str, b: str) -> tuple[str, int]:
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

    def gMultiply(a: str, b: str) -> str:
        assert_(not a.startswith("-"))
        assert_(not a.startswith("-"))
        acc_str, acc = gMultiply_(a, b)
        mask = gMask(acc_str)
        try:
            i = blade_masks.index(mask)
        except ValueError:
            raise ValueError(f"Missing blade {acc_str}")
        blade = blades[i]
        acc *= sign(gMultiply_(blade, "1")[1])

        if acc == 0: return "0"
        sign_ = "-" if acc == -1 else ""
        return f"{sign_}{blade}"

    return [[gMultiply(v, w) for w in blades] for v in blades]

PGA_2D = GAlgebra(mul_table([0, 1, 1], ["1", "e0", "e1", "e2", "e01", "e20", "e12", "e012"]))

# Todo: PGA_2D.expand("(v1+v2e0) * (v1+v2e0)") # left and right must already be expanded
# PGA_2D.expand("(v1+v2e0) *~ (v1+v2e0)")
# PGA_2D.expand("ae20 sandwich b") == PGA_2D.expand(f"{PGA_2D.expand("b * ae20")} *~ b")
# PGA_2D.expand("-9.8e20 sandwich (1)")
