package threads_utils
import "../mem"
import "base:intrinsics"

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

// globals
semaphore: OsSemaphore
total_thread_count := 1

running_thread_count := 1
pending_async_files := 0 // TODO: delete this

// types
ThreadInfo :: struct #align (mem.CACHE_LINE_SIZE) {
	temporary_allocator_data: mem.ArenaAllocator `fmt:"-"`,
	os_info:                  OsThreadInfo,
	index:                    u32,
}
#assert(size_of(ThreadInfo) <= mem.CACHE_LINE_SIZE)
#assert((size_of(ThreadInfo) % mem.CACHE_LINE_SIZE) == 0)
