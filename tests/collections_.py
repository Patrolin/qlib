from qLib.tests import test, run_tests
from qLib.collections_ import normalize, string_similarity, Set, Map
from typing import NamedTuple, Callable

class NormalizeTest(NamedTuple):
    string: str
    expected: Callable[[bool, bool, bool], str]

@test
def testNormalize():
    assert normalize("á") == "a"
    assert normalize("B") == "b"
    assert normalize("Č") == "c"
    assert normalize("ﬁ") == "fi"

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
            assert got == expected, f"{repr(got)} {repr(expected)} {c} {a} {s}"

@test
def testStringSimilarity():
    assert string_similarity("app", "no") == 0.0
    assert string_similarity("app", "orange") == 0.10686629932510841
    assert string_similarity("app", "pineapple") == 0.26712224516570116
    assert string_similarity("app", "apole") == 0.31066746727980593
    assert string_similarity("app", "apple") == 0.682679419970128

@test
def testSet():
    set = Set()

    set.add("A")
    assert set.has("A")
    set.add("B")
    assert set.has("B")
    set.add("C")
    assert set.has("C")

    assert set.has("A")
    assert set.has("B")
    assert set.has("C")

    set.remove("A")
    assert not set.has("A")
    assert set.has("B")
    assert set.has("C")

    assert set["B"]
    assert set["C"]

@test
def testMap():
    map = Map()

    map["A"] = 1
    assert map["A"] == 1
    map["B"] = 2
    assert map["B"] == 2
    map["C"] = 3
    assert map["C"] == 3

    assert map.has("A")
    assert map.has("B")
    assert map.has("C")

    map.remove("A")
    assert not map.has("A")
    assert map.has("B")
    assert map.has("C")

    assert map["B"] == 2
    assert map["C"] == 3

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
                if map[c] != ord(c):
                    for i, bucket in enumerate(map.buckets):
                        print(i, bucket)
                    print(c, hash(c) % map.bucket_count)
                assert map[c] == ord(c)

if __name__ == "__main__":
    run_tests()
