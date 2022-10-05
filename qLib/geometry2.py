from typing import NamedTuple, Union
from qLib.collections_ import find, findIndex
from .tests import assert_, assert_equals, assert_greater_than_equals
from .math_ import reduce, sign

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

    def parse_blade_normalized(s: str, i: int) -> tuple["Blade", int]:
        # TODO: proper parse_int()
        # sign
        acc = 1
        while i < len(s) and s[i] == "-":
            acc *= -1
            i += 1
        # value
        j = i
        while j < len(s) and s[j].isnumeric():
            j += 1
        acc *= int(s[i:j] or "1")
        # TODO: parse_op()?
        i = j
        # blade
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
                acc *= bases[int(acc_str[i]) - min_basis]
                acc_str = acc_str[:i - 1] + acc_str[i + 1:]
        return Blade(acc, "", f"e{acc_str}" if acc_str else "1"), len(s)

    def genBlades():
        acc: list[str] = []
        for i in range(0, 2**len(bases)):
            str_bases = "".join(f"{j+min_basis}" for (j, v) in enumerate(bases) if (1 << j) & i)
            str_blade = f"e{str_bases}" if len(str_bases) > 0 else "1"
            acc.append(str_blade)
        return sorted(acc, key=lambda v: (len(v), v))

    str_blades = genBlades()
    blades: list["Blade"] = []
    pseudoscalar: "Blade"
    denormalize: dict[int, "Blade"] = {}

    def bladeMask(name: str) -> int:
        return reduce(name[1:], lambda acc, v: acc ^ (1 << int(v)), 0)

    for override in signs:
        for i, str_blade in enumerate(str_blades):
            if bladeMask(override) == bladeMask(str_blade):
                str_blades[i] = override

    def denormalize_blade(normalized_blade: "Blade") -> "Blade":
        unit = denormalize[bladeMask(normalized_blade.name)]
        return Blade(normalized_blade.value * unit.value, normalized_blade.str_value, unit.name)

    class Blade:
        def __init__(self, value: Union[int, float], str_value: str, name: str):
            self.value = value
            self.str_value = str_value
            self.name = name

        def __repr__(self):
            return f"{self.value}{self.str_value}{self.name if self.name != '1' else ''}"

        def __add__(self, other: "Blade") -> "Blade":
            assert_equals(self.str_value, other.str_value)
            assert_equals(self.name, other.name)
            return Blade(self.value + other.value, self.str_value, self.name)

        def __mul__(self, other: Union[int, float, "Blade"]) -> "Blade":
            if isinstance(other, Blade):
                blade_normalized, i = parse_blade_normalized(f"e{self.name[1:]}{other.name[1:]}", 0)
                assert_greater_than_equals(i, 0)
                blade_normalized.value *= self.value * other.value
                blade_normalized.str_value = self.str_value + other.str_value
                return denormalize_blade(blade_normalized)
            else:
                return Blade(self.value * other, self.str_value, self.name)

        def __rmul__(self, other: Union[int, float]):
            return self * other

        def right_complement(self) -> "Blade":
            missigned_dual = denormalize[bladeMask(self.name) ^ bladeMask(pseudoscalar.name)]
            product = Blade(1, "", self.name) * missigned_dual
            assert_equals(abs(product.value), 1)
            assert_equals(product.name, pseudoscalar.name)
            sign_correction = 1 - 2 * (product.value == -1)
            return Blade(self.value * missigned_dual.value * sign_correction, self.str_value, missigned_dual.name)

        def left_complement(self) -> "Blade":
            missigned_dual = denormalize[bladeMask(self.name) ^ bladeMask(pseudoscalar.name)]
            product = missigned_dual * Blade(1, "", self.name)
            assert_equals(abs(product.value), 1)
            assert_equals(product.name, pseudoscalar.name)
            sign_correction = 1 - 2 * (product.value == -1)
            return Blade(self.value * missigned_dual.value * sign_correction, self.str_value, missigned_dual.name)

    for str_blade in str_blades:
        blade = Blade(1, "", str_blade)
        denormalize[bladeMask(str_blade)] = blade
        blades.append(blade)
    pseudoscalar = blades[-1]
    assert_equals(len(denormalize), 2**(positive + negative + zero))

    class Multivector:
        values: list[Blade] = []
        # TODO

    class GAlgebra:
        name = f"G_{positive},{negative},{zero}"
        blades: list[Blade]

        @staticmethod
        def parse_blade(s: str):
            blade, i = parse_blade_normalized(s, 0)
            return denormalize_blade(blade), i

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
        GAlgebra.name = f"Vector Algebra {positive}D"
    elif negative == 0 and zero == 1:
        GAlgebra.name = f"Projective Algebra {positive}D"
    elif negative == 1 and zero == 0:
        GAlgebra.name = f"Conformal Algebra {positive-1}D"

    return GAlgebra

PGA2D_ = GAlgebra(2, 0, 1, start_with_zero=True, signs=["e20"])
