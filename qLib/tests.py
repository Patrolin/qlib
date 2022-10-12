__all__ = [
    "assert_never", "assert_equals", "assert_not_equals", "assert_less_than_equals", "assert_greater_than_equals", "assert_", "test",
    "run_tests"
]

from types import FrameType
from typing import Callable, NamedTuple, cast
from traceback import print_exc
from qLib.vtcodes import TextColor
from inspect import currentframe, getframeinfo
from os.path import basename

def assert_never(error: str):
    raise AssertionError(error)

def assert_equals(got, expected):
    if got != expected:
        raise AssertionError(f"got: {got}; expected: {expected}")

def assert_not_equals(got, expected):
    if got == expected:
        raise AssertionError(f"got: {got}; expected: not {expected}")

def assert_less_than_equals(got, expected):
    if got > expected:
        raise AssertionError(f"got: {got}; expected: <= {expected}")

def assert_greater_than_equals(got, expected):
    if got < expected:
        raise AssertionError(f"got: {got}; expected: >= {expected}")

def assert_(*conditions: bool):
    if not all(conditions):
        raise AssertionError(f"got: {conditions}")

class _Test(NamedTuple):
    f: Callable
    file_name: str

_tests: list[_Test] = []

def test(callback: Callable) -> Callable:
    current_frame = cast(FrameType, currentframe())
    caller_frame = cast(FrameType, current_frame.f_back)
    file_path, *_ = getframeinfo(caller_frame)
    file_name = basename(file_path)
    _tests.append(_Test(callback, file_name))
    return callback

def run_tests():
    passed = 0
    failed = 0
    for test in _tests:
        name = f"#{passed + failed + 1} {test.file_name}/{test.f.__name__}"
        try:
            test.f()
            print(f"{TextColor.GREEN}{name} passed{TextColor.RESET}")
            passed += 1
        except Exception:
            print(f"{TextColor.RED}{name} failed:")
            print_exc()
            print(f"{TextColor.RESET}")
            failed += 1

    print(f"    {TextColor.GREEN if failed == 0 else TextColor.RED}{passed} passed {failed} failed{TextColor.RESET}")
    exit(failed)
