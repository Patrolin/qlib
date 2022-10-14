from qLib import *

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
    assert_equals(parseString("\"234.6\\u901\""), ("234.6", -11))
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

if __name__ == "__main__":
    run_tests()
