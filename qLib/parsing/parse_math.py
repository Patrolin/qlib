from typing import cast

from qLib.tests import assert_not_equals

def parseTokens(s: str, splitOn: str, i=0) -> list[str]:
    acc: list[str] = []
    while i < len(s):
        while i < len(s) and s[i] in " \n":
            i += 1
        while i < len(s) and s[i] in splitOn:
            acc.append(s[i])
            i += 1
        while i < len(s) and s[i] in " \n":
            i += 1
        j = i
        while j < len(s) and s[j] not in f"{splitOn} \n":
            j += 1
        if j != i:
            acc.append(s[i:j])
        i = j
    return acc

def parseOp(s: str, i=0) -> tuple[str, int]:
    while i < len(s) and s[i] != " ":
        i += 1
    return s[:i], i

class MathNode:
    def __init__(self, value: str, left=None, right=None):
        self.value = value
        self.left: MathNode | None = left
        self.right: MathNode | None = right

    def __repr__(self):
        return self.tprint()

    def tprint(self, i=0) -> str:
        acc = f"{i*'  '}{self.value}"
        if self.left != None: acc += f"\n{self.left.tprint(i+1)}"
        if self.right != None: acc += f"\n{self.right.tprint(i+1)}"
        return acc

    def __eq__(self, other):
        if not isinstance(other, MathNode): return False
        return (self.value == other.value) and (self.left == other.left) and (self.right == other.right)

MATH_SYMBOLS = "+-*/()"

def _parseMath(tokens: list[str]) -> MathNode | None:
    if len(tokens) == 0: return None
    noop = acc = MathNode("(")
    brackets = []
    i = 0
    while i < len(tokens):
        # unary
        unary = acc
        while i < len(tokens):
            token = tokens[i]
            i += 1
            if token == ")":
                acc = brackets.pop()
                acc.right = acc.right.right
                assert_not_equals(acc.right, None)
                print(f"UNARY; {token}; \n{acc}")
                continue
            unary.right = MathNode(token)
            unary = unary.right
            if token == "(":
                brackets.append(acc)
                acc = unary
                print(f"UNARY; {token}; \n{acc}")
            elif token != "-":
                print(f"UNARY; {token}; \n{acc}")
                break
        # binary
        while i < len(tokens):
            token = tokens[i]
            if token == "(":
                acc.right = MathNode(token)
                brackets.append(acc)
                acc = acc.right
            elif token == ")":
                print(f"BRACKETS; {brackets}")
                acc = brackets.pop()
                acc.right = acc.right.right
                assert_not_equals(acc.right, None)
            else:
                if token in MATH_SYMBOLS:
                    new = MathNode(token)
                    new.left = acc
                    acc = new
                else:
                    new = MathNode("*")
                    new.left = acc
                    new.right = MathNode(token)
                    acc = new
                    i += 1
                    print(f"BINARY; {token}; \n{acc}")
                    continue
            print(f"BINARY; {token}; \n{acc}")
            i += 1
            break
    first = cast(MathNode, noop.right)
    noop.value = first.value
    noop.right = first.right
    print(f"brackets; {len(brackets)}")
    return acc

def parseMath(s: str, i=0):
    tokens = parseTokens(s, MATH_SYMBOLS, i)
    print("tokens", tokens)
    return _parseMath(tokens)

# 1 + (2 + 3)
# node(node(1, 2), 3)
