package os_utils
import "../fmt"
import "core:strings"
import win "core:sys/windows"

// types
FileHandle :: win.HANDLE
File :: struct {
	handle:          FileHandle,
	size:            int,
	last_write_time: int,
}
FileView :: struct {
	file:    File,
	mapping: win.HANDLE,
	data:    []byte `fmt:"-"`,
}

// windows helper functions
LOBYTE :: #force_inline proc "contextless" (v: $T) -> u8 {return u8(v)}
HIBYTE :: #force_inline proc "contextless" (v: $T) -> u8 {return u8(v >> 8)}
LOWORD :: #force_inline proc "contextless" (v: $T) -> u16 {return u16(v)}
HIWORD :: #force_inline proc "contextless" (v: $T) -> u16 {return u16(v >> 16)}
LOIWORD :: #force_inline proc "contextless" (v: $T) -> i16 {return i16(v)}
HIIWORD :: #force_inline proc "contextless" (v: $T) -> i16 {return i16(v >> 16)}
MAKEWORD :: #force_inline proc "contextless" (hi, lo: u32) -> u32 {return (hi << 16) | lo}

// string procedures
@(private)
win_string_to_wstring :: proc(str: string, allocator := context.temp_allocator) -> win.wstring {
	return win.utf8_to_wstring(str, allocator = allocator)
}
@(private)
win_wstring_to_string :: proc(wstr: []win.WCHAR, allocator := context.temp_allocator) -> string {
	res, _ := win.wstring_to_utf8(raw_data(wstr), len(wstr), allocator = allocator)
	return res
}
@(private)
win_null_terminated_wstring_to_string :: proc(wstr: [^]win.WCHAR, allocator := context.temp_allocator) -> string {
	res, _ := win.wstring_to_utf8(wstr, -1, allocator = allocator)
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

// dir and file procedures
move_path :: proc(old_path: string, new_path: string) -> (ok: bool) {
	return win.MoveFileExW(win_string_to_wstring(old_path), win_string_to_wstring(new_path), 0) == true
}
get_path_type :: proc(path: string) -> (path_type: PathType) {
	attributes := win.GetFileAttributesW(win_string_to_wstring(path))
	path_type = (attributes & win.FILE_ATTRIBUTE_DIRECTORY) == win.FILE_ATTRIBUTE_DIRECTORY ? .Directory : .File
	path_type = attributes == win.INVALID_FILE_ATTRIBUTES ? .None : path_type
	return
}
delete_path_recursively :: proc(path: string) {
	assert_path_is_safe_to_delete(path)
	path_type := get_path_type(path)
	switch path_type {
	case .None:
	case .File:
		delete_file(path)
	case .Directory:
		// TODO: write these wstrings into a shared buffer instead?
		path_to_search := fmt.tprintf("%v\\*", path)
		wpath_to_search := win_string_to_wstring(path_to_search)
		find_result: win.WIN32_FIND_DATAW
		find := win.FindFirstFileW(wpath_to_search, &find_result)
		if find != win.INVALID_HANDLE_VALUE {
			for {
				relative_path := win_null_terminated_wstring_to_string(&find_result.cFileName[0])
				if relative_path != "." && relative_path != ".." {
					delete_path_recursively(fmt.tprint(path, relative_path, separator = "/"))
				}
				if win.FindNextFileW(find, &find_result) == false {break}
			}
			win.FindClose(find)
		}
		delete_directory_if_empty(path)
	}
}

// dir procedures
delete_directory_if_empty :: proc(dir_path: string) {
	win.RemoveDirectoryW(win_string_to_wstring(dir_path))
}
new_directory :: proc(dir_path: string) -> (ok: bool) {
	return win.CreateDirectoryW(win_string_to_wstring(dir_path), nil) == true
}

// file procedures
delete_file :: proc(file_path: string) {
	win.DeleteFileW(win_string_to_wstring(file_path))
}
open_file :: proc(file_path: string, options: FileOptions) -> (file: File, ok: bool) {
	file_path_w := win_string_to_wstring(file_path)
	for_writing := options >= {.WriteOnly} || options >= {.ReadWrite}

	dwDesiredAccess := options >= {.WriteOnly} ? 0 : win.GENERIC_READ
	dwDesiredAccess |= for_writing ? win.GENERIC_WRITE : 0
	dwShareMode := options >= {.UniqueAccess} ? 0 : win.FILE_SHARE_READ | win.FILE_SHARE_WRITE
	/*securityAttributes := win.SECURITY_ATTRIBUTES { // NOTE: i don't think you ever want this
		nLength        = size_of(win.SECURITY_ATTRIBUTES),
		bInheritHandle = true,
	}*/
	dwCreationDisposition := for_writing ? win.OPEN_ALWAYS : win.OPEN_EXISTING
	dwCreationDisposition = options >= {.Truncate} ? win.CREATE_ALWAYS : dwCreationDisposition
	dwFlagsAndAttributes := win.FILE_ATTRIBUTE_NORMAL
	dwFlagsAndAttributes |= options >= {.RandomAccess} ? win.FILE_FLAG_RANDOM_ACCESS : win.FILE_FLAG_SEQUENTIAL_SCAN

	file_handle := win.CreateFileW(file_path_w, dwDesiredAccess, dwShareMode, nil, dwCreationDisposition, dwFlagsAndAttributes, nil)
	if file_handle != win.INVALID_HANDLE_VALUE {
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
	assert(win.CloseHandle(file.handle) == true)
}
@(require_results)
read_file :: proc(file_handle: FileHandle, buffer: []byte) -> (byte_count_read: int) {
	bytes_to_read_u32 := u32(min(len(buffer), int(max(u32))))
	read_byte_count_word: win.DWORD
	win.ReadFile(file_handle, raw_data(buffer), bytes_to_read_u32, &read_byte_count_word, nil)
	return int(read_byte_count_word)
}
@(require_results)
write_file :: proc(file_handle: FileHandle, buffer: []byte) -> (byte_count_written: int) {
	bytes_to_write_u32 := u32(min(len(buffer), int(max(u32))))
	written_byte_count_word: win.DWORD
	win.WriteFile(file_handle, raw_data(buffer), bytes_to_write_u32, &written_byte_count_word, nil)
	return int(written_byte_count_word)
}
flush_file :: proc(file_handle: FileHandle) {
	win.FlushFileBuffers(file_handle)
}

// file_view procedures
open_file_view :: proc(file_view: ^FileView, new_size: int) -> (ok: bool) {
	assert(file_view.file.handle != nil)
	// set the file size
	dwMaximumSizeHigh := u32((new_size) >> 32)
	dwMaximumSizeLow := u32(new_size)
	fmt.printfln("file_view.file.size: %v, new_size: %v", file_view.file.size, new_size)
	if file_view.file.size != new_size {
		win.SetFilePointer(file_view.file.handle, i32(dwMaximumSizeLow), (^i32)(&dwMaximumSizeHigh), win.FILE_BEGIN)
		win.SetEndOfFile(file_view.file.handle)
	}
	file_view.file.size = new_size

	// reopen the file_view
	file_view.mapping = win.CreateFileMappingW(file_view.file.handle, nil, win.PAGE_READWRITE, dwMaximumSizeHigh, dwMaximumSizeLow, nil)
	if file_view.mapping == nil {return false}
	ptr := win.MapViewOfFile(file_view.mapping, win.FILE_MAP_READ | win.FILE_MAP_WRITE, 0, 0, 0)
	file_view.data = ([^]byte)(ptr)[:new_size]
	return true
}
close_file_view :: proc(file_view: FileView) {
	assert(win.UnmapViewOfFile(raw_data(file_view.data)) == true)
	assert(win.CloseHandle(file_view.mapping) == true)
}
resize_file_view :: proc(file_view: ^FileView, new_size: int) -> (ok: bool) {
	close_file_view(file_view^)
	// set the file size
	dwMaximumSizeHigh := u32((new_size) >> 32)
	dwMaximumSizeLow := u32(new_size)
	if file_view.file.size != new_size {
		win.SetFilePointer(file_view.file.handle, i32(dwMaximumSizeLow), (^i32)(&dwMaximumSizeHigh), win.FILE_BEGIN)
		win.SetEndOfFile(file_view.file.handle)
	}
	file_view.file.size = new_size
	// reopen the file_view
	file_view.mapping = win.CreateFileMappingW(file_view.file.handle, nil, win.PAGE_READWRITE, dwMaximumSizeHigh, dwMaximumSizeLow, nil)
	if file_view.mapping == nil {return false}
	ptr := win.MapViewOfFile(file_view.mapping, win.FILE_MAP_READ | win.FILE_MAP_WRITE, 0, 0, 0)
	file_view.data = ([^]byte)(ptr)[:new_size]
	return true
}
