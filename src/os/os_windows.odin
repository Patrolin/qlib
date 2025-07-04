package os_utils
import "../fmt"
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

// string procedures
win_string_to_wstring :: win.utf8_to_wstring
win_wstring_to_string :: proc(str: []win.WCHAR, allocator := context.temp_allocator) -> string {
	res, _ := win.wstring_to_utf8(raw_data(str), len(str), allocator = allocator)
	return res
}
win_null_terminated_wstring_to_string :: proc(str: [^]win.WCHAR, allocator := context.temp_allocator) -> string {
	res, _ := win.wstring_to_utf8(str, -1, allocator = allocator)
	return res
}
win_get_last_error_message :: proc() -> (error: u32, error_message: string) {
	error = win.GetLastError()
	error_message = ""
	buffer: [1024]win.WCHAR
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

// file procedures
open_file :: proc(file_path: string, options: FileOptions) -> (file: File, ok: bool) {
	file_path_w := win_string_to_wstring(file_path)

	dwDesiredAccess := options >= {.Read} ? win.GENERIC_READ : 0
	dwDesiredAccess |= options >= {.Write_Truncate} || options >= {.Write_Preserve} ? win.GENERIC_WRITE : 0
	dwShareMode := options >= {.UniqueAccess} ? 0 : win.FILE_SHARE_READ | win.FILE_SHARE_WRITE
	/*securityAttributes := win.SECURITY_ATTRIBUTES { // NOTE: i don't think you ever want this
		nLength        = size_of(win.SECURITY_ATTRIBUTES),
		bInheritHandle = true,
	}*/
	dwCreationDisposition := win.OPEN_EXISTING
	dwCreationDisposition = options >= {.Write_Preserve} ? win.OPEN_ALWAYS : dwCreationDisposition
	dwCreationDisposition = options >= {.Write_Truncate} ? win.CREATE_ALWAYS : dwCreationDisposition
	dwFlagsAndAttributes := win.FILE_ATTRIBUTE_NORMAL

	file_handle := win.CreateFileW(file_path_w, dwDesiredAccess, dwShareMode, nil, dwCreationDisposition, dwFlagsAndAttributes, nil)
	if file_handle != nil {
		win_stats: win.BY_HANDLE_FILE_INFORMATION
		win.GetFileInformationByHandle(file_handle, &win_stats)
		file = File {
			file_handle,
			int(win_stats.nFileSizeHigh) << 32 | int(win_stats.nFileSizeLow),
			int(win_stats.ftLastWriteTime.dwHighDateTime) << 32 | int(win_stats.ftLastWriteTime.dwLowDateTime),
		}
		ok = true
	}
	return
}
close_file :: proc(file: File) {
	win.CloseHandle(file.handle)
}

map_view_of_file :: proc(file: File) -> (data: []byte, ok: bool) {
	dwMaximumSizeHigh := u32((file.file_size) >> 32)
	dwMaximumSizeLow := u32(file.file_size)
	mapping := win.CreateFileMappingW(file.handle, nil, win.PAGE_READWRITE, dwMaximumSizeHigh, dwMaximumSizeLow, nil)
	ptr := win.MapViewOfFile(mapping, win.FILE_MAP_READ | win.FILE_MAP_WRITE, 0, 0, uint(file.file_size))
	fmt.println(win_get_last_error_message())
	return ([^]byte)(ptr)[:file.file_size], ptr != nil
}

read_file :: proc(file_handle: FileHandle, buffer: []byte) -> (byte_count_read: int) {
	bytes_to_read_u32 := u32(min(len(buffer), int(max(u32))))
	byte_count_written_word: win.DWORD
	win.ReadFile(file_handle, raw_data(buffer), bytes_to_read_u32, &byte_count_written_word, nil)
	return int(byte_count_written_word)
}
write_file :: proc(file_handle: FileHandle, buffer: []byte) -> (byte_count_written: int) {
	bytes_to_write_u32 := u32(min(len(buffer), int(max(u32))))
	byte_count_written_word: win.DWORD
	win.WriteFile(file_handle, raw_data(buffer), bytes_to_write_u32, &byte_count_written_word, nil)
	return int(byte_count_written_word)
}
