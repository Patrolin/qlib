from qlib.tests import assert_, assert_equals, test, run_tests
from qlib.collections_ import normalize, string_similarity, Set, Map
from typing import NamedTuple, Callable

# TODO: tests

class NormalizeTest(NamedTuple):
    string: str
    expected: Callable[[bool, bool, bool], str]

@test
def testNormalize():
    assert_equals(normalize("á"), "a")
    assert_equals(normalize("B"), "b")
    assert_equals(normalize("Č"), "c")
    assert_equals(normalize("ﬁ"), "fi")

    tests = [
        NormalizeTest("á", lambda c, a, s: ["a", "a\u0301"][a]),
        NormalizeTest("B", lambda c, a, s: ["b", "B"][c]),
        NormalizeTest("Č", lambda c, a, s: ["c", "C", "c\u030c", "C\u030c"][a*2 + c]),
        NormalizeTest("ﬁ", lambda c, a, s: ["fi", "ﬁ"][s]),
    ]
    for i in range(16):
        c = (i % 2) == 0
        a = (i % 4) == 0
        s = (i % 8) == 0
        for t in tests:
            got = normalize(t.string, case_sensitive=c, accent_sensitive=a, symbol_sensitive=s)
            expected = t.expected(c, a, s)
            assert_equals(got, expected)

@test
def testStringSimilarity():
    assert_equals(string_similarity("app", "no"), 0.0)
    assert_equals(string_similarity("app", "orange"), 0.10686629932510841)
    assert_equals(string_similarity("app", "pineapple"), 0.26712224516570116)
    assert_equals(string_similarity("app", "apole"), 0.31066746727980593)
    assert_equals(string_similarity("app", "apple"), 0.682679419970128)

@test
def testSet():
    set = Set()

    set.add("A")
    assert_(set.has("A"))
    set.add("B")
    assert_(set.has("A"), set.has("B"))
    set.add("C")
    assert_(set.has("A"), set.has("B"), set.has("C"))

    set.remove("A")
    assert_(not set.has("A"), set.has("B"), set.has("C"))
    assert_(set["B"], set["C"])

@test
def testMap():
    map = Map()

    map["A"] = 1
    assert_equals(map["A"], 1)
    map["B"] = 2
    assert_equals(map["B"], 2)
    map["C"] = 3
    assert_equals(map["C"], 3)
    assert_(map.has("A"), map.has("B"), map.has("C"))

    map.remove("A")
    assert_(not map.has("A"), map.has("B"), map.has("C"))
    assert_equals(map["B"], 2)
    assert_equals(map["C"], 3)

ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

@test
def testFuzzMap():
    for start in range(0, len(ALPHABET)):
        for end in range(1, len(ALPHABET) + 1):
            sliced_alphabet = ALPHABET[start:end]
            map = Map()
            for c in sliced_alphabet:
                map[c] = ord(c)
            for c in sliced_alphabet:
                assert_equals(map[c], ord(c))

if __name__ == "__main__":
    run_tests()
