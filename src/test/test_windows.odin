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
	result := win.WaitForSingleObject(os_thread_info.handle, milliseconds)
	return result == win.WAIT_OBJECT_0
}
@(private)
_exit :: proc(exit_code: u32) {
	win.ExitProcess(exit_code)
}
