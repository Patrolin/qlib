// odin run tests -no-crt -default-to-nil-allocator -no-thread-local -linker:radlink
package tests
import "../src/test"
import threads_utils "../src/threads"
import "alloc"
import "math"
import "mem"
import "threads"
import "time"

main :: proc() {
	// math, test
	test.run_tests(
		"math",
		{
			{"test_count_leading_zeros", math.test_count_leading_zeros},
			{"test_log2_floor", math.test_log2_floor},
			{"test_log2_ceil", math.test_log2_ceil},
			{"test_round_floor_ceil", math.test_round_floor_ceil},
		},
	)
	// mem, os
	context = threads_utils.init()
	test.run_tests(
		"mem",
		{
			{"test_virtual_alloc", mem.test_virtual_alloc},
			{"test_arena_allocator", mem.test_arena_allocator},
			{"test_pool_alloc", mem.test_pool_alloc},
			{"test_half_fit_allocator", mem.test_half_fit_allocator},
		},
	)
	// threads, alloc, time
	test.run_tests(
		"threads",
		{
			{"test_default_context", threads.test_default_context},
			{"test_work_queue", threads.test_work_queue},
		},
	)
	test.run_tests("alloc", {{"test_map", alloc.test_map}, {"test_set", alloc.test_set}})
	test.run_tests("time", {{"test_sleep_ns", time.test_sleep_ns}})
	// cleanup
	for &thread_info in threads_utils.thread_infos {
		if thread_info.os_info.handle != nil {
			threads_utils.stop_os_thread(&thread_info)
		}
	}
}
