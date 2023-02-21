from .parse_int import *
from .parse_float import *
from .parse_string import *

def tokenize(s: str, *, include="", exclude=" \t\r\n") -> list[str]:
    acc = []
    i = 0
    while i < len(s):
        if s[i] in include:
            acc.append(s[i])
            i += 1
        while i < len(s) and s[i] in exclude:
            i += 1
        j = i
        while j < len(s) and (s[j] not in include) and (s[j] not in exclude):
            j += 1
        if j != i:
            acc.append(s[i:j])
        i = j
    return acc
