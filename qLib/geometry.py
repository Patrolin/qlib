from typing import Optional, Union

from qLib.collections_ import find, findIndex
from .tests import assert_equals, assert_, assert_not_equals
from .math_ import reduce, sign

def gMask(e: str) -> int:
    return reduce(e[1:], lambda acc, v: acc ^ (1 << int(v)), 0)

def parse_blade_normal_form(bases: list[int], min_blade: int, str_blade: str) -> tuple[int, int]:
    # parse blade, sorting and combining bases in increasing order
    for base in bases:
        assert_((base == 1) or (base == 0) or (base == -1))
    assert_(not str_blade.startswith("-"))
    if str_blade == "0": return 0, 0
    acc_str = ""
    acc = 1
    for v in str_blade[1:]:
        acc_str += v
        i = len(acc_str) - 1
        while i > 0:
            if acc_str[i - 1] <= acc_str[i]: break
            acc *= -1
            tmp = acc_str[i] + acc_str[i - 1]
            acc_str = acc_str[:i - 1] + tmp + acc_str[i + 1:]
            i -= 1
        if i - 1 >= 0 and acc_str[i] == acc_str[i - 1]:
            acc *= bases[int(acc_str[i]) - min_blade]
            acc_str = acc_str[:i - 1] + acc_str[i + 1:]
    return gMask(f"e{acc_str}"), acc

def serialize_blade(acc: Union[int, float], str_blade: str) -> str:
    if str_blade.removeprefix("-") == "1": return f"{acc}"
    if acc == 0: return "0"
    if acc == 1: return str_blade
    if acc == -1: return f"-{str_blade}"
    return f"{acc}{str_blade}"

def gMultiply(str_mul_table: list[list[str]], a: str, b: str) -> str:
    negate = a.startswith("-") ^ b.startswith("-")
    i = findIndex(str_mul_table[0], lambda v: v == a.removeprefix("-"))
    j = findIndex(str_mul_table[0], lambda v: v == b.removeprefix("-"))
    return f"{'-' if negate else ''}{str_mul_table[i][j]}".removeprefix("--")

def gDivide(str_mul_table: list[list[str]], a: str, b: str) -> tuple[int, str]:
    str_blades = str_mul_table[0]
    mask = gMask(a) ^ gMask(b)
    blade = find(str_blades, lambda v: gMask(v) == mask)
    negate = gMultiply(str_mul_table, a, "1").startswith("-") ^ gMultiply(str_mul_table, b, blade).startswith("-")
    return 1 - 2*negate, blade

def GAlgebra(str_mul_table: list[list[str]]):
    str_blades = str_mul_table[0]
    assert_equals(str_blades[0], "1")
    for v in str_blades:
        assert_not_equals(v[0], "-")
    str_vector_blades = [v for v in str_blades if len(v) == 2]
    str_pseudoscalar = "e" + "".join(v[1] for v in str_vector_blades)
    mul_table: list[list["GBlade"]] = []
    nondegenerate_map: list["GBlade"] = []

    class GBlade:
        def __init__(self, index: int, value: Union[int, float]):
            self.value = int(value) if isinstance(value, float) and value.is_integer() else value
            self.index = index if value != 0.0 else 0

        def __repr__(self):
            return serialize_blade(self.value, str_blades[self.index])

        def __eq__(self, other: Union["GBlade", int, float]):
            if isinstance(other, GBlade):
                return (self.index == other.index) & (self.value == other.value)
            else:
                return (self.index == 0) & (self.value == other)

        # sum = A+B, A-B
        def __add__(self, other: "GBlade"):
            assert_equals(self.index, other.index)
            return GBlade(self.index, self.value + other.value)

        def __sub__(self, other: "GBlade"):
            assert_equals(self.index, other.index)
            return GBlade(self.index, self.value - other.value)

        # geometric product = A*B
        def __mul__(self, other: Union["GBlade", int, float]):
            if isinstance(other, GBlade):
                v = mul_table[self.index][other.index]
                return GBlade(v.index, v.value * self.value * other.value)
            else:
                return GBlade(self.index, self.value * other)

        def __rmul__(self, other: Union[int, float]):
            return self * other

        def __neg__(self):
            return self * -1

        def __truediv__(self, other: Union[int, float]):
            return self * (1/other)

        # grade
        def grade(self):
            return len(str_blades[self.index]) - 1

        def gradeSelect(self, n: int):
            return self * (self.grade() == n)

        # A^\dagger = A.reverse() = ~A
        def __invert__(self):
            sign = 1 - 2 * ((self.grade() // 2) % 2)
            return self * sign

        # \overline{A}^\dagger = A.involute()
        def involute(self):
            return self * (-1)**self.grade()

        # \overline{A} = A.conjugate()
        # A.norm() = A*A.conjugate() # if A is homogeneous?
        def conjugate(self):
            return ~self.involute() # = (-1)**(self.grade()*(self.grade()+1)/2)

        ## poincare dualities
        def right_complement(self):
            acc, str_blade = gDivide(str_mul_table, str_pseudoscalar, str_blades[self.index])
            index = findIndex(str_blades, lambda v: v == str_blade)
            #assert_equals() A^A.right_complement() = pseudoscalar
            the_complement = GBlade(index, self.value * acc)
            assert_equals(self * the_complement, mul_table[0][-1] * abs(self.value))
            return the_complement

        def nondegenerate(self):
            return nondegenerate_map[self.index] * self.value

        # hodge dual = A.dual()
        def dual(self):
            nondegenerate = self.nondegenerate()
            acc = sign((nondegenerate * ~nondegenerate).value)
            the_dual = self.right_complement() * acc
            assert_equals(self * the_dual, acc * mul_table[0][-1] * abs(self.value))
            return the_dual

        def undual(self):
            the_dual = self.dual()
            acc = sign(the_dual.dual().value * self.value)
            return acc * the_dual

        # dot product
        def dot(self, other: "GBlade"):
            return (self * other).gradeSelect(0).value

        # inner product
        def inner(self, other: "GBlade"):
            return (self * other).gradeSelect(abs(self.grade() - other.grade()))

        # left_contraction = (A outer B.dual()).undual()
        def left_contraction(self, other: "GBlade"):
            return (self * other).gradeSelect(other.grade() - self.grade())

        # wedge product = (A left_contraction B.dual()).undual()
        # = A&B = (A.dual() | B.dual()).undual()
        def __and__(self, other: "GBlade"):
            return (self * other).gradeSelect(self.grade() + other.grade())

        # antiwedge (regressive) product = A|B = (A.dual() & B.dual()).undual()
        def __or__(self, other: "GBlade"):
            return (self.dual() & other.dual()).undual()

        # commutator product
        def commutator(self, other: Union["GBlade", int, float]):
            if isinstance(other, GBlade):
                return (self*other - other*self) / 2
            else:
                return self.commutator(GBlade(0, other))

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
            index = str_blades.index(s[i:j]) if j != i else 0 # todo: allow parsing reversed blades
            return GBlade(index, value), j

        @staticmethod
        def parse_expression(s: str, i: int) -> tuple[GMultivector, int]:
            pass

    def genNondegenerate(str_blade: str) -> GBlade:
        acc = 1

        def is_degenerate(blade: GBlade):
            return (blade * blade) == 0

        str_nondegenerate_bases = ""
        for (i, basis) in enumerate(str_blade[1:]):
            if is_degenerate(GAlgebra.parse_blade(f"e{basis}", 0)[0]):
                acc *= (-1)**i
            else:
                str_nondegenerate_bases += basis
        str_nondegenerate_blade = f"e{str_nondegenerate_bases}" if len(str_nondegenerate_bases) > 0 else "1"
        return GAlgebra.parse_blade(str_nondegenerate_blade, 0)[0] * acc

    mul_table = [[GAlgebra.parse_blade(v, 0)[0] for v in row] for row in str_mul_table]
    nondegenerate_map = [genNondegenerate(v) for v in str_mul_table[0]]
    unique_blades = set(v.index for v in mul_table[0])
    assert_equals(len(str_blades), len(unique_blades))
    assert_equals(len(str_blades), len(mul_table))
    assert_(all(v.nondegenerate() * v.nondegenerate() != 0 for v in mul_table[0]))

    GAlgebra.blades = mul_table[0]

    return GAlgebra

def mul_table(bases: list[int], blades: Optional[list[str]] = None, min_blade=1):
    def gGenBlades():
        acc: list[str] = []
        for i in range(0, 2**len(bases)):
            str_bases = "".join(f"{j+min_blade}" for (j, v) in enumerate(bases) if (1 << j) & i)
            str_blade = f"e{str_bases}" if len(str_bases) > 0 else "1"
            acc.append(str_blade)
        return sorted(acc, key=lambda v: (len(v), v))

    if blades != None:
        min_blade = int(blades[1][1:])
    else:
        blades = gGenBlades()
    #print(blades)

    def gGenMultiply(a: str, b: str) -> str:
        if a == "0" or b == "0": return "0"
        mask, acc = parse_blade_normal_form(bases, min_blade, f"e{a[1:]}{b[1:]}")
        blade = find(blades, lambda v: gMask(v) == mask)
        acc *= parse_blade_normal_form(bases, min_blade, blade)[1]
        return serialize_blade(acc, blade)

    # todo: this is O((2**len(bases))**2)...
    return [[gGenMultiply(v, w) for w in blades] for v in blades]

PGA_2D = GAlgebra(mul_table([0, 1, 1], ["1", "e0", "e1", "e2", "e01", "e20", "e12", "e012"]))
PGA_3D = GAlgebra(
    mul_table([0, 1, 1, 1],
              ['1', 'e1', 'e2', 'e3', 'e4', 'e12', 'e13', 'e14', 'e23', 'e24', 'e34', 'e123', 'e124', 'e134', 'e234', 'e1234']))
VGA_2D = GAlgebra(mul_table([1, 1], ["1", "e1", "e2", "e12"]))
VGA_3D = GAlgebra(mul_table([1, 1, 1], ["1", "e1", "e2", "e3", "e12", "e13", "e23", "e123"]))
CGA_2D = GAlgebra(mul_table([1, 1, 1, -1], min_blade=1))
#CONIC_GA_2D = GAlgebra(mul_table([1, 1, 1, 1, 1, -1, -1, -1], min_blade=1))
#QUADRIC_GA_3D = GAlgebra(mul_table([1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1], min_blade=1))

# Todo: PGA_2D.table("A*~A")
# Todo: PGA_2D.expand("(v1+v2e0) * (v1+v2e0)") # left and right must already be expanded
# PGA_2D.expand("(v1+v2e0) *~ (v1+v2e0)")
# PGA_2D.expand("ae20 sandwich b") == PGA_2D.expand(f"{PGA_2D.expand("b * ae20")} *~ b")
# PGA_2D.expand("-9.8e20 sandwich (1)")
