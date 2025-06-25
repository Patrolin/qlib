package tests
import "../src/math"
import "../src/mem"
import "../src/test"
import "../src/threads"
import "base:intrinsics"
import "base:runtime"

test_virtual_alloc :: proc() {
	data := mem.page_alloc(threads.VIRTUAL_MEMORY_TO_RESERVE, false)
	test.expectf(
		data != nil,
		"Failed to page_alloc(threads.VIRTUAL_MEMORY_TO_RESERVE), data: %v",
		data,
	)
	for offset := 0; offset < threads.VIRTUAL_MEMORY_TO_RESERVE; offset += mem.PAGE_SIZE {
		raw_data(data)[offset] = 13
	}
	data = mem.page_alloc_aligned(64 * math.KIBI_BYTES, 64 * math.KIBI_BYTES)
	test.expectf(data != nil, "Failed to page_alloc_aligned(64 kiB, 64 kiB), data: %v", data)
	data_ptr := &data[0]
	low_bits := uintptr(data_ptr) & math.low_mask(uintptr(16))
	test.expectf(
		low_bits == 0,
		"Failed to page_alloc_aligned(64 kiB, 64 kiB), low_bits: %v",
		low_bits,
	)
}

test_pool_alloc :: proc() {
	buffer := mem.page_alloc(mem.PAGE_SIZE)
	pool_64b := mem.pool_allocator(buffer, 8)

	x := (^int)(mem.pool_alloc(&pool_64b))
	test.expect_was_allocated(x, "x", 13)

	y := (^int)(mem.pool_alloc(&pool_64b))
	test.expect_was_allocated(y, "y", 7)
	test.expect_still_allocated(x, "x", 13)

	mem.pool_free(&pool_64b, x)
	mem.pool_free(&pool_64b, y)
}

test_half_fit_allocator :: proc() {
	buffer := mem.page_alloc(mem.PAGE_SIZE)
	assert(uintptr(raw_data(buffer)) & uintptr(63) == 0)
	half_fit: mem.HalfFitAllocator
	mem.half_fit_allocator_init(&half_fit, buffer)
	context.allocator = runtime.Allocator {
		data      = &half_fit,
		procedure = mem.half_fit_allocator_proc,
	}
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
	buffer := mem.page_alloc(mem.PAGE_SIZE)
	arena_allocator := mem.arena_allocator(buffer)
	context.allocator = runtime.Allocator{mem.arena_allocator_proc, &arena_allocator}

	x := new(int)
	test.expect_was_allocated(x, "x", 13)

	y := new(int)
	test.expect_was_allocated(y, "y", 7)
	test.expect_still_allocated(x, "x", 13)

	free(x)
	free(y)
}
