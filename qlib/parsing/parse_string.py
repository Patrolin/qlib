from qlib.parsing.parse_int import parseInt
from os import getcwd as _getcwd

def parseString(string: str) -> tuple[str, int]:
    if len(string) == 0 or string[0] != "\"":
        return "", 0
    acc = ""
    i = 1
    while i < len(string):
        if string[i] == "\\":
            i += 1
            if i >= len(string):
                break
            if string[i] == "u":
                i += 1
                c, j = parseInt(string[i:i + 4], base=16)
                if j != 4: break
                i += 4
                acc += chr(c)
            else:
                acc += string[i]
                i += 1
        elif string[i] == "\"":
            return acc, i + 1
        else:
            acc += string[i]
            i += 1
    return acc, -i

def printString(string: str) -> str:
    acc = ""
    for c in string:
        if c == "\"":
            acc += "\\\""
        else:
            acc += c
    return f"\"{acc}\""

_cwd = _getcwd()

def printRelativePath(relative_path: str) -> str:
    BACKSLASH = "\\"
    return f"{_cwd.replace(BACKSLASH, '/')}/{relative_path.removeprefix('/')}"
