// odin run tests -no-crt -default-to-nil-allocator -no-thread-local -linker:radlink -vet-unused
// TODO: use -vet instead
package tests
import "../src/test"
import "../src/threads"

main :: proc() {
	// fmt, math, test
	test.group("fmt")
	test.run_test(test_fmt)
	test.group_end()

	test.group("math")
	test.run_test(test_count_leading_zeros)
	test.run_test(test_log2_floor)
	test.run_test(test_log2_ceil)
	test.run_test(test_round_floor_ceil)
	test.group_end()

	// mem, os
	context = threads.init()
	test.group("mem")
	test.run_test(test_virtual_alloc)
	test.run_test(test_arena_allocator)
	test.run_test(test_pool_alloc)
	test.run_test(test_half_fit_allocator)
	test.group_end()

	// threads, alloc, time
	test.group("threads")
	test.run_test(test_default_context)
	test.run_test(test_work_queue)
	test.group_end()

	test.group("alloc")
	test.run_test(test_map)
	test.run_test(test_set)
	test.group_end()

	test.group("time")
	test.run_test(test_sleep_ns)
	test.group_end()

	// cleanup
	for &thread_info in threads.thread_infos {
		if thread_info.os_info.handle != nil {
			threads.stop_os_thread(&thread_info)
		}
	}
}
