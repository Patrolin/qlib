from typing import Any, Callable, NamedTuple, TypeVar, cast
from traceback import print_exc as _print_exc
from qlib.vtcodes import TextColor
from inspect import currentframe as _currentframe, getframeinfo as _getframeinfo
from os.path import basename as _basename

def assert_fail(error: str):
    raise AssertionError(error)

def _pretty_print(value: Any):
    if "\n" in str(value):
        return f"\n{str(value)}"
    else:
        return repr(value)

def assert_equals(got, expected):
    if got != expected:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: {_pretty_print(expected)}")

def assert_not_equals(got, expected):
    if got == expected:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: not {_pretty_print(expected)}")

def assert_is_close(got: float, expected: float):
    if abs(got - expected) > 1e-7:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: {_pretty_print(expected)}")

T = TypeVar("T")

def as_not_null(value: T | None) -> T:
    assert_not_equals(value, None)
    return cast(T, value)

def assert_less_than(got, expected):
    if got >= expected:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: < {_pretty_print(expected)}")

def assert_greater_than(got, expected):
    if got <= expected:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: > {_pretty_print(expected)}")

def assert_less_than_equals(got, expected):
    if got > expected:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: <= {_pretty_print(expected)}")

def assert_greater_than_equals(got, expected):
    if got < expected:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: >= {_pretty_print(expected)}")

def assert_between(got, expectedLow, expectedHigh):
    if (got < expectedLow) or (got > expectedHigh):
        raise AssertionError(f"got: {_pretty_print(got)}; expected: >= {_pretty_print(expectedLow)} and <= {_pretty_print(expectedHigh)}")

def assert_in(got, expected):
    if got not in expected:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: in {_pretty_print(expected)}")

def assert_not_in(got, expected):
    if got in expected:
        raise AssertionError(f"got: {_pretty_print(got)}; expected: not in {_pretty_print(expected)}")

def assert_(*conditions: bool, message=""):
    if not all(conditions):
        raise AssertionError(f"got: {conditions}")

class _Test(NamedTuple):
    f: Callable
    file_name: str

_tests: list[_Test] = []

def test(callback: Callable) -> Callable:
    current_frame = as_not_null(_currentframe())
    caller_frame = as_not_null(current_frame.f_back)
    file_path, *_ = _getframeinfo(caller_frame)
    file_name = _basename(file_path)
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
            _print_exc()
            print(f"{TextColor.RESET}")
            failed += 1

    print(f"    {TextColor.GREEN if failed == 0 else TextColor.RED}{passed} passed {failed} failed{TextColor.RESET}")
    exit(failed)
