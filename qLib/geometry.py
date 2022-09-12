from .tests import assert_equals, assert_greater_than_equals
from .math_ import sign

def gMask(e: str) -> int:
    acc = 0
    for c in e:
        acc |= (1 << int(c))
    return acc

def gMultiply_(bases: list[int], e1: str, e2: str) -> tuple[str, int]:
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
    return acc_str, acc

def gMultiply(bases: list[int], names: list[str], e1: str, e2: str) -> str:
    acc_str, acc = gMultiply_(bases, e1, e2)
    mask = gMask(acc_str)
    i = 0
    for n in names:
        if gMask(n[1:]) == mask:
            break
        i += 1
    else:
        i = -1
    name_ = names[i] if i >= 0 else ""
    #print(acc_str, acc, acc * sign(gMultiply_(bases, name_, "")[1]))
    acc *= sign(gMultiply_(bases, name_, "")[1])
    name = name_ or "1"

    #print(acc, acc_str)
    if acc == 0: return "0"
    sign_ = "-" if acc == -1 else ""
    return f"{sign_}{name}"

def gAntiCommutative_(bases: list[int], names: list[str], e1: str, e2: str) -> bool:
    a = gMultiply(bases, names, e1, e2)
    b = gMultiply(bases, names, e2, e1)
    return a.startswith("-") ^ b.startswith("-")

def gInner(bases: list[int], names: list[str], e1: str, e2: str) -> str:
    return gMultiply(bases, names, e1, e2) if not gAntiCommutative_(bases, names, e1, e2) else "0"

def gOuter(bases: list[int], names: list[str], e1: str, e2: str) -> str:
    return gMultiply(bases, names, e1, e2) if gAntiCommutative_(bases, names, e1, e2) else "0"

def galgebra(bases: list[int], names: list[str]):
    assert_equals(len(names), 2**len(bases) - 1)
    for v in names:
        assert_greater_than_equals(len(v), 2)
        assert_equals(v[0], "e")
        for c in v[1:]:
            assert_equals(c.isnumeric(), True)
    masks = [gMask(v[1:]) for v in names]
    print(masks)
    print("-- v * w")
    for v in ["", *names]:
        print([gMultiply(bases, names, v, w) for w in ["", *names]])
    print("-- v inner w")
    for v in ["", *names]:
        print([gInner(bases, names, v, w) for w in ["", *names]])
    print("-- v outer w")
    for v in ["", *names]:
        print([gOuter(bases, names, v, w) for w in ["", *names]])

    class GAlgebra:
        pass

    return GAlgebra

PGA_2D = galgebra([0, 1, 1], ["e0", "e1", "e2", "e01", "e20", "e12", "e012"])
