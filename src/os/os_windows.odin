package os_utils
import "../math"
import "core:strings"
import win "core:sys/windows"

// windows helper functions
LOBYTE :: #force_inline proc "contextless" (v: $T) -> u8 {return u8(v & 0xff)}
HIBYTE :: #force_inline proc "contextless" (v: $T) -> u8 {return u8(v >> 8)}
LOWORD :: #force_inline proc "contextless" (v: $T) -> u16 {return u16(v & 0xffff)}
HIWORD :: #force_inline proc "contextless" (v: $T) -> u16 {return u16(v >> 16)}
LOIWORD :: #force_inline proc "contextless" (v: $T) -> i16 {return i16(v & 0xffff)}
HIIWORD :: #force_inline proc "contextless" (v: $T) -> i16 {return i16(v >> 16)}
MAKEWORD :: #force_inline proc "contextless" (hi, lo: u32) -> u32 {return (hi << 16) | lo}

// procedures
// TODO: can we just use -A functions instead?
win_string_to_wstring :: win.utf8_to_wstring
win_wstring_to_string :: proc(str: []win.WCHAR, allocator := context.temp_allocator) -> string {
	res, _ := win.wstring_to_utf8(raw_data(str), len(str), allocator = allocator)
	return res
}
win_null_terminated_wstring_to_string :: proc(
	str: [^]win.WCHAR,
	allocator := context.temp_allocator,
) -> string {
	res, _ := win.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
win_get_last_error_message :: proc() -> (error: u32, error_message: string) {
	error = win.GetLastError()
	error_message = ""
	buffer: [64]win.WCHAR
	format_result := win.FormatMessageW(
		win.FORMAT_MESSAGE_FROM_SYSTEM | win.FORMAT_MESSAGE_IGNORE_INSERTS,
		nil,
		error,
		0,
		&buffer[0],
		len(buffer),
		nil,
	)
	if format_result != 0 {
		error_message = win_null_terminated_wstring_to_string(&buffer[0])
		if strings.ends_with(error_message, "\r\n") {
			error_message = error_message[:len(error_message) - 2]
		}
	} else {
		error_message = "BUFFER_TOO_SMALL_FOR_ERROR_MESSAGE"
	}
	return
}
win_get_monitor_rect :: proc(window_handle: win.HWND) -> math.RelativeRect {
	monitor := win.MonitorFromWindow(
		window_handle,
		win.Monitor_From_Flags.MONITOR_DEFAULTTONEAREST,
	)
	info := win.MONITORINFO {
		cbSize = size_of(win.MONITORINFO),
	}
	assert(bool(win.GetMonitorInfoW(monitor, &info)))
	monitor_rect := info.rcMonitor
	return math.relative_rect(
		{monitor_rect.left, monitor_rect.top, monitor_rect.right, monitor_rect.bottom},
	)
}
win_get_window_rect :: proc(window_handle: win.HWND) -> math.RelativeRect {
	window_rect: win.RECT
	win.GetWindowRect(window_handle, &window_rect)
	return math.relative_rect(
		{window_rect.left, window_rect.top, window_rect.right, window_rect.bottom},
	)
}
win_get_client_rect :: proc(
	window_handle: win.HWND,
	window_rect: math.RelativeRect,
) -> math.RelativeRect {
	win_client_rect: win.RECT
	win.GetClientRect(window_handle, &win_client_rect)
	window_border := info.window_border
	return {
		window_rect.left + window_border.left,
		window_rect.top + window_border.top,
		win_client_rect.right - win_client_rect.left,
		win_client_rect.bottom - win_client_rect.top,
	}
}
win_get_cursor_pos :: proc() -> math.i32x2 {
	pos: win.POINT
	win.GetCursorPos(&pos)
	return {pos.x, pos.y}
}
