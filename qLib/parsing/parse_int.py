from qLib.collections_ import findIndexOrDefault
from qLib.parsing import DIGITS

def parseInt(s: str, *, base=10) -> tuple[int, int]:
    i = 0
    acc = 0
    while i < len(s):
        if s[i] == "_":
            i += 1
            continue
        j = findIndexOrDefault(DIGITS[:base], lambda v: v == s[i])
        if j < 0: break
        acc = acc*base + j # TODO: error on overflow?
        i += 1
    return acc, i

# TODO: parseSignedInt

def printInt(int_: int, *, base=10) -> str:
    if int_ == 0: return "0"
    acc_string = ""
    acc = abs(int_)
    while acc > 0:
        rem = acc % base
        acc_string += DIGITS[rem]
        acc = acc // base
    acc_string_reversed = ""
    for i in range(1, len(acc_string) + 1):
        acc_string_reversed += acc_string[len(acc_string) - i]
    sign = "" if (int_ > 0) else "-"
    return sign + acc_string_reversed
