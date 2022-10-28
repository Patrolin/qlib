from typing import cast

from qLib.tests import assert_, assert_equals, assert_not_equals

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

BINARY_OPERATORS = "+-*/"
MATH_SYMBOLS = f"{BINARY_OPERATORS}()"
_DEBUG = False

def parseMath(s: str, i=0) -> MathNode:
    tokens = parseTokens(s, MATH_SYMBOLS, i)
    if _DEBUG: print("tokens", tokens)
    acc = MathNode("(")
    brackets: list[MathNode] = []
    i = 0
    while i < len(tokens):
        # unary
        unary = acc
        while (unary.value in BINARY_OPERATORS) and (unary.right != None):
            unary = unary.right
        while i < len(tokens):
            token = tokens[i]
            i += 1
            if token == ")":
                acc = brackets.pop()
                assert_not_equals(acc.right, None)
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
            elif token == "(":
                if unary.value != "(":
                    unary.right = MathNode(token)
                    unary = unary.right
                brackets.append(acc)
                acc = unary
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
            else:
                if unary.value == "(":
                    unary.value = token
                else:
                    unary.right = MathNode(token)
                    unary = unary.right
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
                if token != "-": break
        # binary
        while i < len(tokens):
            token = tokens[i]
            if token == ")":
                acc = brackets.pop()
                assert_not_equals(acc.right, None)
                i += 1
                if _DEBUG: print(f"BINARY; {token}; \n{acc}")
                continue
            elif token in BINARY_OPERATORS:
                old = MathNode(acc.value, acc.left, acc.right)
                acc.value = token
                acc.left = old
                acc.right = None
            else:
                curr = acc
                while (curr.value in BINARY_OPERATORS) and (curr.right != None):
                    curr = curr.right
                old = MathNode(curr.value, curr.left, curr.right)
                curr.value = "*"
                curr.left = old
                curr.right = None
                if _DEBUG: print(f"BINARY; {token}; \n{acc}")
                break
            i += 1
            if _DEBUG: print(f"BINARY; {token}; \n{acc}")
            break
    assert_equals(len(brackets), 0)
    return acc

def parseExpression(s: str, i=0) -> MathNode:
    tokens = parseTokens(s, MATH_SYMBOLS, i)
    if _DEBUG: print("tokens", tokens)
    acc = MathNode("(")
    brackets: list[MathNode] = []
    i = 0
    while i < len(tokens):
        # unary
        unary = acc
        while i < len(tokens):
            token = tokens[i]
            i += 1
            if token == ")":
                acc = brackets.pop()
                assert_not_equals(acc.right, None)
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
            elif token == "(":
                if unary.value != "(":
                    unary.right = MathNode(token)
                    unary = unary.right
                brackets.append(acc)
                acc = unary
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
            else:
                if unary.value == "(":
                    unary.value = token
                else:
                    unary.right = MathNode(token)
                    unary = unary.right
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
                if token != "-": break
        # binary
        while i < len(tokens):
            token = tokens[i]
            if token == ")":
                acc = brackets.pop()
                assert_not_equals(acc.right, None)
                i += 1
                if _DEBUG: print(f"BINARY; {token}; \n{acc}")
                continue
            else:
                old = MathNode(acc.value, acc.left, acc.right)
                acc.value = token
                acc.left = old
                acc.right = None
            i += 1
            if _DEBUG: print(f"BINARY; {token}; \n{acc}")
            break
    assert_equals(len(brackets), 0)
    return acc
