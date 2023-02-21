from qlib.parsing import tokenize
from qlib.tests import as_not_null, assert_less_than, assert_never

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

UNARY_OPS = "-"
BINARY_OPS = "+-*/"
MATH_SYMBOLS = f"{''.join(set([*UNARY_OPS, *BINARY_OPS]))}()"

def parseMath(s: str) -> MathNode:
    return _parseMath(tokenize(s, include=MATH_SYMBOLS))[1]

def _parseMath(tokens: list[str]) -> tuple[int, MathNode]:
    i, root = parseUnaryOp(tokens)
    while i < len(tokens):
        # binary
        if tokens[i] == ")": break
        root = MathNode(tokens[i], root)
        i += 1
        # unary
        j, unary = parseUnaryOp(tokens[i:])
        i += j
        root.right = unary
    return i, root

def parseUnaryOp(tokens: list[str]) -> tuple[int, MathNode]:
    root = MathNode("")
    acc = root
    i = 0
    while i < len(tokens) and tokens[i] in UNARY_OPS:
        acc.right = MathNode(tokens[i])
        acc = acc.right
        i += 1
    assert_less_than(i, len(tokens))
    if tokens[i] in BINARY_OPS:
        assert_never(f"Invalid token: {tokens[i:]}")
    if tokens[i] == "(":
        j, bracket = _parseMath(tokens[i + 1:])
        acc.right = bracket
        i += j + 2
    else:
        acc.right = MathNode(tokens[i])
        i += 1
    return i, as_not_null(root.right)
