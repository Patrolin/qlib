// odin run tests -no-crt -default-to-nil-allocator -no-thread-local -linker:radlink
package tests
import "../src/test"
import "../src/threads"

main :: proc() {
	// fmt, math, test
	test.run_tests("fmt", {{"test_fmt", test_fmt}})
	test.run_tests(
		"math",
		{
			{"test_count_leading_zeros", test_count_leading_zeros},
			{"test_log2_floor", test_log2_floor},
			{"test_log2_ceil", test_log2_ceil},
			{"test_round_floor_ceil", test_round_floor_ceil},
		},
	)

	// mem, os
	context = threads.init()
	test.run_tests(
		"mem",
		{
			{"test_virtual_alloc", test_virtual_alloc},
			{"test_arena_allocator", test_arena_allocator},
			{"test_pool_alloc", test_pool_alloc},
			{"test_half_fit_allocator", test_half_fit_allocator},
		},
	)
	// threads, alloc, time
	test.run_tests(
		"threads",
		{{"test_default_context", test_default_context}, {"test_work_queue", test_work_queue}},
	)
	test.run_tests("alloc", {{"test_map", test_map}, {"test_set", test_set}})
	test.run_tests("time", {{"test_sleep_ns", test_sleep_ns}})

	// cleanup
	for &thread_info in threads.thread_infos {
		if thread_info.os_info.handle != nil {
			threads.stop_os_thread(&thread_info)
		}
	}
}
