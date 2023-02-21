from qlib.tests import assert_between

def getDigit(char: str) -> int:
    if "0" <= char <= "9":
        return ord(char) - ord("0")
    elif "A" <= char <= "Z":
        return ord(char) - ord("A") + 10
    elif "a" <= char <= "z":
        return ord(char) - ord("a") + 10
    else:
        return -1

def parseInt(s: str, *, base=10) -> tuple[int, int]:
    assert_between(base, 2, 16)
    i = 0
    acc = 0
    while i < len(s):
        if s[i] == "_":
            i += 1
            continue
        j = getDigit(s[i])
        if j < 0 or j >= base: break
        acc = acc*base + j
        i += 1
    return acc, i

def parseSignedInt(s: str, *, base=10) -> tuple[int, int]:
    is_negative = (s[0] == "-")
    acc, i = parseInt(s[is_negative:], base=base)
    return acc * (1 - 2*is_negative), i + is_negative

def parseU64(s: str, *, base=10) -> tuple[int, int]:
    acc, i = parseInt(s, base=base)
    assert_between(acc, 0, 2**64 - 1)
    return acc, i

def parseS64(s: str, *, base=10) -> tuple[int, int]:
    acc, i = parseSignedInt(s, base=base)
    assert_between(acc, -2**63, 2**63 - 1)
    return acc, i

BASE16_DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

def printInt(int_: int, *, base=10) -> str:
    assert_between(base, 2, 16)
    if int_ == 0: return "0"
    acc_string = ""
    acc = abs(int_)
    while acc > 0:
        rem = acc % base
        acc_string += BASE16_DIGITS[rem]
        acc = acc // base
    acc_string_reversed = ""
    for i in range(1, len(acc_string) + 1):
        acc_string_reversed += acc_string[len(acc_string) - i]
    sign = "" if (int_ > 0) else "-"
    return sign + acc_string_reversed
