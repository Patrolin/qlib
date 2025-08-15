package lib_mem
import "../math"
import "base:intrinsics"
import "core:mem"

// types
ArenaAllocator :: struct {
	buffer: []byte `fmt:"%p"`,
	next:   int,
	/* we will assume single threaded, this is just here to catch bugs */
	lock:   Lock,
}

// procedures
arena_allocator :: proc(arena_allocator: ^ArenaAllocator, buffer: []byte) -> mem.Allocator {
	arena_allocator^ = ArenaAllocator{buffer, 0, false}
	return mem.Allocator{arena_allocator_proc, arena_allocator}
}
arena_allocator_proc :: proc(
	allocator: rawptr,
	mode: mem.Allocator_Mode,
	size, _alignment: int,
	old_ptr: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: mem.Allocator_Error,
) {
	DEBUG :: false
	when DEBUG {fmt.printfln("mode: %v, size: %v, loc: %v", mode, size, loc)}

	arena_allocator := (^ArenaAllocator)(allocator)
	// assert single threaded
	ok := get_lock_or_error(&arena_allocator.lock)
	assert(ok, loc = loc)
	defer release_lock(&arena_allocator.lock)

	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		ptr := _arena_alloc(arena_allocator, size)
		data = ptr[:size]
		err = arena_allocator.next > len(arena_allocator.buffer) ? .Out_Of_Memory : .None
	case .Resize, .Resize_Non_Zeroed:
		// alloc
		ptr := _arena_alloc(arena_allocator, size)
		data = ptr[:size]
		if (intrinsics.expect(arena_allocator.next > len(arena_allocator.buffer), false)) {
			err = .Out_Of_Memory
			break
		}
		// copy
		size_to_copy := min(size, old_size)
		copy_simd_64B(old_ptr, size_to_copy, ptr)
	case .Free_All:
		arena_allocator.next = 0
	}
	return
}
@(private)
_arena_alloc :: proc(arena_allocator: ^ArenaAllocator, size: int) -> (ptr: [^]byte) {
	ptr = math.ptr_add(raw_data(arena_allocator.buffer), arena_allocator.next)

	alignment_offset := math.align_forward(ptr, 64) // align to 64B, so we can do a faster copy when resizing
	ptr = math.ptr_add(ptr, alignment_offset)

	arena_allocator.next += size + alignment_offset
	return
}
