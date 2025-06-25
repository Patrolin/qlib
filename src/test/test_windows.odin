package test_utils
import win "core:sys/windows"

@(private)
_OsThreadInfo :: struct {
	id:     u32,
	handle: win.HANDLE,
}
@(private)
_create_thread :: proc(
	stack_size: int,
	thread_proc: proc "std" (_: rawptr) -> u32,
	param: rawptr,
) -> (
	os_thread_info: _OsThreadInfo,
) {
	os_thread_info.handle = win.CreateThread(
		nil,
		uint(stack_size),
		thread_proc,
		param,
		0,
		&os_thread_info.id,
	)
	return
}
@(private)
_wait_for_thread :: proc(os_thread_info: _OsThreadInfo, milliseconds: u32) -> bool {
	return win.WaitForSingleObject(os_thread_info.handle, milliseconds) == win.WAIT_OBJECT_0
}
@(private)
_stop_thread :: proc(os_thread_info: _OsThreadInfo) {
	win.TerminateThread(os_thread_info.handle, 1)
}
