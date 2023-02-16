from qlib import *

@test
def testMeanStdev():
    for arr, u, s in [\
        ([1], 1, 0),
        ([1, 2], 1.5, 0.7071067811865476),
        ([3, 2, 1], 2, 1),
        ([10, 0, -1], 3, 6.082762530298219)
    ]:
        assert_equals(meanOrZero(arr), u)
        assert_equals(stdevOrZero(arr, u), s)

@test
def testMode():
    for arr, acceptable_values in [\
        ([1], {1}),
        ([1, 2], {1, 2}),
        ([1, 1, 2], {1}),
        ([1, 2, 2], {2}),
        ([-1, -1, 0, 0, 1, 1, 2, 2, 2, 3], {2})
    ]:
        assert_contains(modeOrZero(arr), acceptable_values)

if __name__ == "__main__":
    run_tests()
