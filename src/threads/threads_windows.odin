package threads_utils
import "../math"
import "../mem"
import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import win "core:sys/windows"

// types
OsThreadInfo :: struct #packed {
	handle: win.HANDLE,
	id:     u32,
}
OsSemaphore :: distinct win.HANDLE
ThreadProc :: proc "std" (data: rawptr) -> u32

// procedures
launch_os_thread :: proc(stack_size: math.Size, thread_proc: ThreadProc, param: rawptr) -> (os_thread_info: OsThreadInfo) {
	intrinsics.atomic_add(&total_thread_count, 1)
	os_thread_info.handle = win.CreateThread(nil, uint(stack_size), thread_proc, param, 0, &os_thread_info.id)
	return
}
stop_os_thread :: proc(thread_info: ^ThreadInfo) {
	assert(win.TerminateThread(thread_info.os_info.handle, 0) != false)
}
_create_semaphore :: proc(max_count: i32) -> OsSemaphore {
	return OsSemaphore(win.CreateSemaphoreW(nil, 0, max_count, nil))
}
_wait_for_semaphore :: proc() {
	win.WaitForSingleObject(win.HANDLE(semaphore), win.INFINITE)
}
_resume_thread :: proc() {
	win.ReleaseSemaphore(win.HANDLE(semaphore), 1, nil)
}
