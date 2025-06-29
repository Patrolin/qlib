// odin run tests -no-crt -default-to-nil-allocator -no-thread-local -linker:radlink -vet-unused
// TODO: use -vet instead
package tests
import "../src/mem"
import "../src/os"
import "../src/test"

global_allocator: mem.HalfFitAllocator
temp_allocator: mem.ArenaAllocator

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

	// init context
	context = os.init()
	context.allocator = mem.half_fit_allocator(
		&global_allocator,
		mem.page_reserve(mem.VIRTUAL_MEMORY_TO_RESERVE),
	)
	context.temp_allocator = mem.arena_allocator(
		&temp_allocator,
		mem.page_reserve(mem.VIRTUAL_MEMORY_TO_RESERVE),
	)

	// mem, os
	test.group("mem")
	test.run_test(test_virtual_alloc)
	test.run_test(test_arena_allocator)
	test.run_test(test_pool_alloc)
	test.run_test(test_half_fit_allocator)
	test.run_test(test_default_context)
	test.group_end()

	// threads, alloc, time
	/* TODO: threads - setup threads yourself and clean them up
	test.group("threads")
	test.run_test(test_work_queue)
	test.group_end()
	*/

	test.group("alloc")
	test.run_test(test_map)
	test.run_test(test_set)
	test.group_end()

	test.group("time")
	test.run_test(test_now)
	test.run_test(test_sleep_ns)
	test.group_end()
}
