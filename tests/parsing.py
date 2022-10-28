from qLib import *
from qLib.parsing.parse_math import MathNode, parseExpression, parseMath, parseTokens

@test
def testParseInt():
    assert_equals(parseInt("a")[1], 0)
    assert_equals(parseInt("0"), (0, 1))
    assert_equals(parseInt("000"), (0, 3))
    assert_equals(parseInt("123"), (123, 3))
    assert_equals(parseInt("123a"), (123, 3))
    assert_equals(parseInt("1012", base=2), (5, 3))
    assert_equals(parseInt("1a", base=16), (26, 2))

@test
def testParseFloat():
    assert_equals(parseFloat64("a")[1], 0)
    assert_equals(parseFloat64("0"), (0, 1))
    assert_equals(parseFloat64("000"), (0, 3))
    assert_equals(parseFloat64("123"), (123, 3))
    assert_equals(parseFloat64("12.4"), (12.4, 4))
    assert_equals(parseFloat64("123e-6"), (.000123, 6))

@test
def testPrintInt():
    assert_equals(printInt(0), "0")
    assert_equals(printInt(123), "123")
    assert_equals(printInt(-34), "-34")

@test
def testParseString():
    assert_equals(parseString(""), ("", 0))
    assert_equals(parseString("abc"), ("", 0))
    assert_equals(parseString("\""), ("", -1))
    assert_equals(parseString("\"abc"), ("abc", -4))
    assert_equals(parseString("\"abc\""), ("abc", 5))
    assert_equals(parseString("\"hello world\""), ("hello world", 13))
    assert_equals(parseString("\"23456\\\" 01234\""), ("23456\" 01234", 15))
    assert_equals(parseString("\"234.6\\u901\""), ("234.6", -8))
    assert_equals(parseString("\"234.6\\u9012\""), ("234.6递", 13))

@test
def testPrintString():
    assert_equals(printString(""), "\"\"")
    assert_equals(printString("hello world"), "\"hello world\"")
    assert_equals(printString("hello\" world"), "\"hello\\\" world\"")

@test
def testParseOp():
    assert_equals(parseOp(""), ("", 0))
    assert_equals(parseOp("abc"), ("abc", 3))
    assert_equals(parseOp("\""), ("\"", 1))
    assert_equals(parseOp("\"abc"), ("\"abc", 4))
    assert_equals(parseOp("\"abc\""), ("\"abc\"", 5))
    assert_equals(parseOp("\"hello world\""), ("\"hello", 6))
    assert_equals(parseOp("\"23456\\\" 01234\""), ("\"23456\\\"", 8))
    assert_equals(parseOp("\"234.6\\u901\""), ("\"234.6\\u901\"", 12))
    assert_equals(parseOp("\"234.6\\u9012\""), ("\"234.6\\u9012\"", 13))

@test
def testParseTokens():
    assert_equals(parseTokens("1+1 - 2/4", "+-*/"), ["1", "+", "1", "-", "2", "/", "4"])
    assert_equals(parseTokens("2 pow 3", "+-*/"), ["2", "pow", "3"])

@test
def testParseMath():
    assert_equals(parseMath("1+1 - 2/4"),
        MathNode("/", \
            MathNode("-",
                MathNode("+",
                    MathNode("1"),
                    MathNode("1")),
                MathNode("2")),
            MathNode("4")))
    assert_equals(parseMath("1 - (2 3) + 4"),
        MathNode("+", \
            MathNode("-",
                MathNode("1"),
                MathNode("*",
                    MathNode("2"),
                    MathNode("3"))),
            MathNode("4")))
    assert_equals(parseMath("a b + c d"),
        MathNode("+", \
            MathNode("*",
                MathNode("a"),
                MathNode("b")),
            MathNode("*",
                MathNode("c"),
                MathNode("d"))))
    for s in [
            "(cos_LAT cos_LNG) + (cos_LAT sin_LNG e13) + (sin_LAT cos_LNG e12) - (sin_LAT sin_LNG e23)",
            "cos_LAT cos_LNG + cos_LAT sin_LNG e13 + sin_LAT cos_LNG e12 - sin_LAT sin_LNG e23"
    ]:
        assert_equals(parseMath(s),
            MathNode("-", \
            MathNode("+",
                MathNode("+",
                    MathNode("*",
                        MathNode("cos_LAT"),
                        MathNode("cos_LNG")),
                    MathNode("*",
                        MathNode("cos_LAT"),
                        MathNode("*",
                            MathNode("sin_LNG"),
                            MathNode("e13")))),
                MathNode("*",
                    MathNode("sin_LAT"),
                    MathNode("*",
                        MathNode("cos_LNG"),
                        MathNode("e12")))),
            MathNode("*",
                MathNode("sin_LAT"),
                MathNode("*",
                    MathNode("sin_LNG"),
                    MathNode("e23")))))

@test
def testParseExpression():
    assert_equals(parseExpression("2 pow 3"),
        MathNode("pow", \
            MathNode("2"),
            MathNode("3")))

if __name__ == "__main__":
    run_tests()
