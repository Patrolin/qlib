package threads_utils
import "../mem"
import "../os"
import "base:intrinsics"
import "base:runtime"
import "core:fmt"

/* What I want out of a threading api:
	1) framerate independent inputs
	2) the CPU to not be waiting on the result of the GPU, and vice versa
	3) background loading of files

The plan:
	- 1 thread waiting on window/input events
	- 1 (2?) threads reading/writing files // how many threads do we need to max out the (read) bandwidth?
	- 1 simulate_game() thread // running at a fixed framerate
		- can launch more threads to help
	- 1 render_on_gpu() thread // interpolate between the last 2 simulated frames, vsynced to the monitor refresh rate
*/

// constants
VIRTUAL_MEMORY_TO_RESERVE :: 1 << 16

// globals
global_allocator: mem.HalfFitAllocator
thread_infos: [dynamic]ThreadInfo
semaphore: OsSemaphore
total_thread_count := 1

running_thread_count := 1
pending_async_files := 0 // TODO: delete this

// types
ThreadInfo :: struct #align (mem.CACHE_LINE_SIZE) {
	temporary_allocator_data: mem.ArenaAllocator `fmt:"p"`,
	os_info:                  OsThreadInfo,
	index:                    u32,
}
#assert(size_of(ThreadInfo) <= mem.CACHE_LINE_SIZE)
#assert((size_of(ThreadInfo) % mem.CACHE_LINE_SIZE) == 0)

// procedures
/* NOTE: Odin doesn't like mixing if statements and `context = ...`, however I wasn't able to make a minimal repro case, so here we are.. */
init :: proc "contextless" (loc := #caller_location) -> runtime.Context {
	context = os.init()
	assert(thread_infos == nil, loc = loc)

	mem.init_page_fault_handler()
	mem.half_fit_allocator_init(
		&global_allocator,
		mem.page_alloc(VIRTUAL_MEMORY_TO_RESERVE, false),
	)
	context.allocator = runtime.Allocator{mem.half_fit_allocator_proc, &global_allocator}

	reserve(&thread_infos, os.info.logical_core_count)
	for thread_index in 0 ..< os.info.logical_core_count {
		append(&thread_infos, ThreadInfo{})
		thread_info := &thread_infos[thread_index]
		thread_info.temporary_allocator_data = mem.arena_allocator(
			mem.page_alloc(VIRTUAL_MEMORY_TO_RESERVE, false),
		)
		thread_info.index = u32(thread_index)
	}
	assert(len(thread_infos) == os.info.logical_core_count)

	ctx := thread_context(0)
	assert(ctx.allocator.data != nil)
	assert(ctx.temp_allocator.data != nil)
	return ctx
}
free_all_for_tests :: proc "odin" () {
	delete(thread_infos)
}
thread_context :: proc "contextless" (
	thread_index: int,
	loc := #caller_location,
) -> runtime.Context {
	thread_info := &thread_infos[thread_index]

	ctx := os.empty_context()
	ctx.allocator = runtime.Allocator{mem.half_fit_allocator_proc, &global_allocator}
	ctx.temp_allocator = runtime.Allocator {
		mem.arena_allocator_proc,
		&thread_info.temporary_allocator_data,
	}
	ctx.user_index = thread_index
	return ctx
}
