package tests
import "../src/mem"
import "../src/test"
import "base:intrinsics"

test_virtual_alloc :: proc() {
	data := mem.page_reserve(mem.VIRTUAL_MEMORY_TO_RESERVE)
	// check not null
	test.expectf(
		data != nil,
		"Failed to page_reserve(mem.VIRTUAL_MEMORY_TO_RESERVE), data: %v",
		data,
	)
	// check commit on page fault
	for offset := 0; offset < mem.VIRTUAL_MEMORY_TO_RESERVE; offset += mem.PAGE_SIZE {
		raw_data(data)[offset] = 13
	}
	// check is aligned to mem.PAGE_SIZE
	test.expect(
		uintptr(raw_data(data)) & uintptr(mem.PAGE_SIZE - 1) == 0,
		"page_reserve(mem.VIRTUAL_MEMORY_TO_RESERVE) is not aligned to mem.PAGE_SIZE",
	)
}

test_pool_alloc :: proc() {
	pool_allocator_8B: mem.PoolAllocator
	mem.pool_allocator(&pool_allocator_8B, mem.page_reserve(mem.PAGE_SIZE), 8)

	x := (^int)(mem.pool_alloc(&pool_allocator_8B))
	test.expect_was_allocated(x, "x", 13)

	y := (^int)(mem.pool_alloc(&pool_allocator_8B))
	test.expect_was_allocated(y, "y", 7)
	test.expect_still_allocated(x, "x", 13)

	mem.pool_free(&pool_allocator_8B, x)
	mem.pool_free(&pool_allocator_8B, y)
}

test_half_fit_allocator :: proc() {
	half_fit: mem.HalfFitAllocator
	buffer := mem.page_reserve(mem.PAGE_SIZE)
	assert(uintptr(raw_data(buffer)) & uintptr(mem.PAGE_SIZE - 1) == 0)
	context.allocator = mem.half_fit_allocator(&half_fit, buffer)
	mem.half_fit_check_blocks("1.", &half_fit)

	x_raw := new([2]int)
	assert(uintptr(rawptr(x_raw)) & 63 == 0)
	x := (^int)(x_raw)
	test.expect_was_allocated(x, "x", 13)
	mem.half_fit_check_blocks("2.", &half_fit)

	y_raw := new(int)
	assert(uintptr(rawptr(y_raw)) & 63 == 0)
	y := (^int)(y_raw)
	test.expect_was_allocated(y, "y", 7)
	test.expect_still_allocated(x, "x", 13)
	mem.half_fit_check_blocks("3.", &half_fit)

	free(x)
	mem.half_fit_check_blocks("4.", &half_fit)

	free(y)
	mem.half_fit_check_blocks("5.", &half_fit)

	arr: [dynamic]int
	N :: 16
	for i in 0 ..< N {append(&arr, i)}
	mem.half_fit_check_blocks("6.", &half_fit)

	for i in 0 ..< N {append(&arr, N + i)}
	mem.half_fit_check_blocks("7.", &half_fit)
	for i in 0 ..< 2 * N {
		test.expectf(arr[i] == i, "Failed to resize array: %v", arr)
	}

	mem.page_free(raw_data(buffer))
}

test_arena_allocator :: proc() {
	arena_allocator: mem.ArenaAllocator
	context.allocator = mem.arena_allocator(&arena_allocator, mem.page_reserve(mem.PAGE_SIZE))

	x := new(int)
	test.expect_was_allocated(x, "x", 13)

	y := new(int)
	test.expect_was_allocated(y, "y", 7)
	test.expect_still_allocated(x, "x", 13)

	free(x)
	free(y)
}

test_default_context :: proc() {
	// allocator
	x := new(int)
	test.expect_was_allocated(x, "x", 13)
	free(x)

	// temp_allocator
	y := new(int, allocator = context.temp_allocator)
	test.expect_was_allocated(y, "y", 7)
	free(y, allocator = context.temp_allocator)
}
