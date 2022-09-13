from .tests import assert_equals, assert_greater_than_equals
from .math_ import sign

def gMask(e: str) -> int:
    acc = 0
    for c in e[1:]:
        acc |= (1 << int(c))
    return acc

def gMultiply_(bases: list[int], e1: str, e2: str) -> tuple[str, int]:
    if e1 == "0" or e2 == "0": return "0", 0
    acc_str = ""
    acc = 1

    def insort(acc_str_: str, c: str):
        acc_str_ += c
        acc_ = 1
        i = len(acc_str_) - 1
        while i > 0:
            if acc_str_[i - 1] <= acc_str_[i]: break
            acc_ *= -1
            tmp = acc_str_[i] + acc_str_[i - 1]
            acc_str_ = acc_str_[:i - 1] + tmp + acc_str_[i + 1:]
            i -= 1
        if i - 1 >= 0 and acc_str_[i] == acc_str_[i - 1]:
            acc_ *= bases[int(acc_str_[i])]
            acc_str_ = acc_str_[:i - 1] + acc_str_[i + 1:]
        return acc_str_, acc_

    for c in e1[1:]:
        acc_str, k = insort(acc_str, c)
        acc *= k
    for c in e2[1:]:
        acc_str, k = insort(acc_str, c)
        acc *= k
    return acc_str or "1", acc

def gMultiply(bases: list[int], names: list[str], e1: str, e2: str) -> str:
    acc_str, acc = gMultiply_(bases, e1, e2)
    mask = gMask(acc_str)
    i = 0
    for n in names:
        if gMask(n) == mask:
            break
        i += 1
    else:
        i = -1
    name = names[i]
    acc *= sign(gMultiply_(bases, name, "1")[1])

    #print(acc, acc_str)
    if acc == 0: return "0"
    sign_ = "-" if acc == -1 else ""
    return f"{sign_}{name}"

def gAntiCommutative_(bases: list[int], names: list[str], e1: str, e2: str) -> bool:
    a = gMultiply(bases, names, e1, e2)
    b = gMultiply(bases, names, e2, e1)
    return a.startswith("-") ^ b.startswith("-")

def gUp(bases: list[int], names: list[str], e1: str, e2: str) -> str:
    return gMultiply(bases, names, e1, e2) if not gAntiCommutative_(bases, names, e1, e2) else "0"

def gDown(bases: list[int], names: list[str], e1: str, e2: str) -> str:
    return gMultiply(bases, names, e1, e2) if gAntiCommutative_(bases, names, e1, e2) else "0"

def gDual(names: list[str], e1: str) -> str:
    return names[len(names) - names.index(e1) - 1]

def galgebra(bases: list[int], names: list[str]):
    assert_equals(len(names), 2**len(bases))
    for i, v in enumerate(names):
        if i == 0:
            assert_equals(v, "1")
        else:
            assert_greater_than_equals(len(v), 2)
            assert_equals(v[0], "e")
            for c in v[1:]:
                assert_equals(c.isnumeric(), True)
    print([gMask(v) for v in names])
    print(bases, names)
    print("-- v * w")
    for v in names:
        print([gMultiply(bases, names, v, w) for w in names])
    print("-- v up w")
    for v in names:
        print([gUp(bases, names, v, w) for w in names])
    print("-- v down w")
    for v in names:
        print([gDown(bases, names, v, w) for w in names])
    print("-- !v")
    print([gDual(names, v) for v in names])
    print("-- v * !w")
    for v in names:

        def f(e1, e2):
            a = gMultiply(bases, names, e1, gDual(names, e2))
            b = gMultiply(bases, names, gDual(names, e2), e1)
            isAntiCommutative = a.startswith("-") ^ b.startswith("-")
            return a if isAntiCommutative else "0"

        print([f(v, w) for w in names])
    print("-- v sandwich w") # todo: multivector product
    for v in names:

        def f(e1, e2):
            acc_sign = 1
            acc = gMultiply(bases, names, e2, e1)
            acc_sign *= 1 - 2 * acc.startswith("-")
            acc = acc.removeprefix("-")
            acc = gMultiply(bases, names, acc, gDual(names, e2))
            acc_sign *= 1 - 2 * acc.startswith("-")
            acc = acc.removeprefix("-")
            sign = "-" if acc_sign == -1 and acc != "0" else ""
            return f"{sign}{acc}"

        print([f(v, w) for w in names])

    class GAlgebra:
        pass

    return GAlgebra

PGA_2D = galgebra([0, 1, 1], ["1", "e0", "e1", "e2", "e01", "e20", "e12", "e012"])

# Todo: PGA_2D.table("(v1+v2e0) * (v1+v2e0)")
# PGA_2D.table("(v1+v2e0) *~ (v1+v2e0)")
# PGA_2D.table("(ae20) sandwich (b)")
# PGA_2D.table("(-9.8e20) sandwich (1)")
