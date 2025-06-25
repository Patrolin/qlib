package test_utils
import "base:runtime"
import "core:fmt"

// constants
TEST_TIMEOUT_MS :: 1000

// types
@(private)
_TestProcParams :: struct {
	procedure: proc(),
	ctx:       ^runtime.Context,
}
@(private)
_TestContext :: struct {
	passed_count: int,
	failed_count: int,
	failed:       bool,
}

Test :: struct {
	name:      string,
	procedure: proc(),
}
Case :: struct($K: typeid, $V: typeid) {
	key:      K,
	expected: V,
}

// procedures
@(private)
_test_thread_proc :: proc "std" (ptr: rawptr) -> u32 {
	test := (^_TestProcParams)(ptr)
	context = test.ctx^
	test.procedure()
	return 0
}
@(private)
_test_failure_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	test_context.failed = true
	runtime.default_assertion_contextless_failure_proc(prefix, message, loc)
}

test_context: _TestContext
run_tests :: proc(group_name: string, tests: []Test) {
	fmt.println(group_name)
	ctx := context
	ctx.assertion_failure_proc = _test_failure_proc
	test_context = {}
	for test in tests {
		fmt.printfln("  - %v", test.name)
		test_params := _TestProcParams{test.procedure, &ctx}
		os_thread_info := _create_thread(1 << 16, _test_thread_proc, &test_params)
		ok := _wait_for_thread(os_thread_info, TEST_TIMEOUT_MS)
		if ok {
			test_context.passed_count += 1
		} else {
			test_context.failed_count += 1
			if !test_context.failed {fmt.printfln("Timed out. (%v ms)", TEST_TIMEOUT_MS)}
			_exit(1)
		}
	}
	if test_context.failed_count == 0 {
		fmt.printfln("  %v passed.", test_context.passed_count)
	} else {
		fmt.printfln(
			"  %v failed, %v passed.",
			test_context.failed_count,
			test_context.passed_count,
		)
	}
}

expect :: #force_inline proc(
	condition: bool,
	message := #caller_expression(condition),
	loc := #caller_location,
) {
	assert(condition, message, loc = loc)
}
expectf :: #force_inline proc(condition: bool, f: string, args: ..any, loc := #caller_location) {
	fmt.assertf(condition, f, ..args, loc = loc)
}
expect_case :: proc(test_case: Case($K, $V), got: V, got_expression := #caller_expression(got)) {
	fmt.assertf(
		got == test_case.expected,
		"%v: %v, expected: %v",
		got_expression,
		got,
		test_case.expected,
	)
}
expect_was_allocated :: proc(ptr: ^int, name: string, value: int, loc := #caller_location) {
	assert(ptr != nil, "Failed was_allocated - failed to allocate", loc = loc)
	fmt.assertf(ptr^ == 0, "Failed was_allocated - should start zeroed", loc = loc)
	ptr^ = value
	fmt.assertf(ptr^ == value, "Failed was_allocated - failed to write", loc = loc)
}
expect_still_allocated :: proc(ptr: ^int, name: string, value: int, loc := #caller_location) {
	fmt.assertf(
		ptr != nil && ptr^ == value,
		"Failed still_allocated, %v: %v at %v",
		name,
		ptr^,
		ptr,
		loc = loc,
	)
}
