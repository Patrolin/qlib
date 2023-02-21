from qlib.parsing import tokenize
from qlib.tests import assert_equals, assert_not_equals

class MathNode:
    def __init__(self, value: str, left=None, right=None, bracketed=False):
        self.value = value
        self.left: MathNode | None = left
        self.right: MathNode | None = right
        self.bracketed = bracketed

    def __repr__(self):
        return self.tprint()

    def tprint(self, i=0) -> str:
        acc = f"{i*'  '}{'(' if self.bracketed else ''}{self.value}"
        if self.left != None: acc += f"\n{self.left.tprint(i+1)}"
        if self.right != None: acc += f"\n{self.right.tprint(i+1)}"
        return f"{acc}{')' if self.bracketed else ''}"

    def __eq__(self, other):
        if not isinstance(other, MathNode): return False
        return (self.value == other.value) and (self.left == other.left) and (self.right == other.right)

BINARY_OPERATORS = "+-*/"
MATH_SYMBOLS = f"{BINARY_OPERATORS}()"
_DEBUG = False

def parseMath(s: str, implicitMultiplication=True) -> MathNode:
    tokens = tokenize(s, include=MATH_SYMBOLS)
    if _DEBUG: print("tokens", tokens)
    acc = MathNode("(")
    brackets: list[MathNode] = []
    i = 0
    while i < len(tokens):
        # unary
        unary = acc
        while (unary.value in BINARY_OPERATORS) and (unary.right != None) and not unary.bracketed:
            unary = unary.right
        while i < len(tokens):
            token = tokens[i]
            i += 1
            if (token == ")"):
                acc.bracketed = True
                acc = brackets.pop()
                assert_not_equals(acc.right, None)
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
            elif (token == "("):
                if (unary.value != "("):
                    unary.right = MathNode(token)
                    unary = unary.right
                brackets.append(acc)
                acc = unary
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
            else:
                if (unary.value == "("):
                    unary.value = token
                else:
                    unary.right = MathNode(token)
                    unary = unary.right
                if _DEBUG: print(f"UNARY; {token}; \n{acc}")
                if token != "-": break
        # binary
        while i < len(tokens):
            token = tokens[i]
            if (token == ")"):
                acc.bracketed = True
                acc = brackets.pop()
                assert_not_equals(acc.right, None)
                i += 1
                if _DEBUG: print(f"BINARY; {token}; \n{acc}")
                continue
            elif (token in BINARY_OPERATORS) or not implicitMultiplication:
                old = MathNode(acc.value, acc.left, acc.right, acc.bracketed)
                acc.value = token
                acc.left = old
                acc.right = None
                acc.bracketed = False
            else:
                curr = acc
                while (curr.value in BINARY_OPERATORS) and (curr.right != None) and not curr.bracketed:
                    curr = curr.right
                old = MathNode(curr.value, curr.left, curr.right, curr.bracketed)
                curr.value = "*"
                curr.left = old
                curr.right = None
                curr.bracketed = False
                if _DEBUG: print(f"BINARY; {token}; \n{acc}")
                break
            i += 1
            if _DEBUG: print(f"BINARY; {token}; \n{acc}")
            break
    assert_equals(len(brackets), 0)
    return acc
