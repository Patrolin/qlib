from qLib.tests import assert_equals, test, run_tests
from qLib.time_ import *
from typing import NamedTuple

class DateTimeTest(NamedTuple):
    date: list[int]
    gregorianSecond: float
    expectedParts: tuple[int, int, int, int, int, int, int, int]

@test
def testDateTime():
    tests = [
        DateTimeTest([1], 0, (1, 1, 1, 0, 0, 0, 0, 1)),
        DateTimeTest([2], 86400 * 365, (2, 1, 1, 0, 0, 0, 0, 2)),
        DateTimeTest([5], 86400 * (4*365 + 1), (5, 1, 1, 0, 0, 0, 0, 6)),
        DateTimeTest([1970], 62135596800, (1970, 1, 1, 0, 0, 0, 0, 4)),
        DateTimeTest([2022, 5, 13, 23, 59, 59, 999], 63788083199.999, (2022, 5, 13, 23, 59, 59, 999, 5)),
        DateTimeTest([2021, 2, 28, 1, 2, 3, 4], 63750070923.004, (2021, 2, 28, 1, 2, 3, 3, 0)),
        # wrapping
        DateTimeTest([1971, 1, 1, 0, 0, 0, 0], 62167132800, (1971, 1, 1, 0, 0, 0, 0, 5)),
        DateTimeTest([1970, 12, 31 + 1, 0, 0, 0, 0], 62167132800, (1971, 1, 1, 0, 0, 0, 0, 5)),
        DateTimeTest([1971, 1, 31, 0, 0, 0, 0], 62169724800, (1971, 1, 31, 0, 0, 0, 0, 0)),
        DateTimeTest([1970, 12 + 1, 31, 0, 0, 0, 0], 62169724800, (1971, 1, 31, 0, 0, 0, 0, 0)),
        DateTimeTest([1970, 12, 31, 0, 0, 0, 0], 62167046400, (1970, 12, 31, 0, 0, 0, 0, 4)),
        DateTimeTest([1971, 1, 1 - 1, 0, 0, 0, 0], 62167046400, (1970, 12, 31, 0, 0, 0, 0, 4)),
        DateTimeTest([1971, 1 - 1, 31, 0, 0, 0, 0], 62167046400, (1970, 12, 31, 0, 0, 0, 0, 4)),
        DateTimeTest([1970, 12 + 1, 1 - 1, 23, 0, 0, 0], 62167129200, (1970, 12, 31, 23, 0, 0, 0, 4)),
    ]
    for (date, gregorianSecond, expectedParts) in tests:
        assert_equals(DateTime(*date).toParts(), list(expectedParts))
        assert_equals(DateTime(*date).gregorianSecond, gregorianSecond)

if __name__ == "__main__":
    run_tests()
