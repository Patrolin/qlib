package os_utils
import "../fmt"
import "../math"
import "base:intrinsics"
import "core:strings"
import win "core:sys/windows"

// constants
@(private)
DwCreationDisposition :: enum u32 {
	CREATE                  = 1,
	CREATE_OR_OPEN          = 4,
	CREATE_OR_OPEN_TRUNCATE = 2,
	OPEN                    = 3,
	OPEN_TRUNCATE           = 5,
}

// types
FileHandle :: win.HANDLE
File :: struct {
	handle:          FileHandle,
	offset:          int,
	size:            int,
	last_write_time: int,
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

// get sector size
foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "c")
foreign kernel32 {
	GetDiskFreeSpaceW :: proc(lpRootPathName: win.LPCWSTR, lpSectorsPerCluster: win.LPDWORD, lpBytesPerSector: win.LPDWORD, lpNumberOfFreeClusters: win.LPDWORD, lpTotalNumberOfClusters: win.LPDWORD) ---
}
get_disk_block_size :: proc() -> int {
	bytesPerSector, sectorsPerCluster, numFreeClusters, totalClusters: win.DWORD
	GetDiskFreeSpaceW(win_string_to_wstring("C:\\"), &bytesPerSector, &sectorsPerCluster, &numFreeClusters, &totalClusters)
	/*fmt.printfln(
		"bytesPerSector: %v, sectorsPerCluster: %v, numFreeClusters: %v, totalClusters: %v",
		bytesPerSector,
		sectorsPerCluster,
		numFreeClusters,
		totalClusters,
	)*/
	return int(sectorsPerCluster)
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
	read_only := options >= {.ReadOnly}

	dwDesiredAccess := options >= {.WriteOnly} ? 0 : win.GENERIC_READ
	dwDesiredAccess |= read_only ? 0 : win.GENERIC_WRITE

	dwShareMode := options >= {.UniqueAccess} ? 0 : win.FILE_SHARE_READ | win.FILE_SHARE_WRITE

	dwCreationDisposition: DwCreationDisposition = read_only ? .OPEN : .CREATE_OR_OPEN
	dwCreationDisposition = options >= {.NoOpen} ? .CREATE : dwCreationDisposition
	dwCreationDisposition = options >= {.Truncate} ? .CREATE_OR_OPEN_TRUNCATE : dwCreationDisposition

	dwFlagsAndAttributes := win.FILE_ATTRIBUTE_NORMAL
	dwFlagsAndAttributes |= options >= {.RandomAccess} ? win.FILE_FLAG_RANDOM_ACCESS : win.FILE_FLAG_SEQUENTIAL_SCAN
	dwFlagsAndAttributes |= options >= {.NoBuffering} ? win.FILE_FLAG_NO_BUFFERING : 0
	dwFlagsAndAttributes |= options >= {.FlushOnWrite} ? win.FILE_FLAG_WRITE_THROUGH : 0

	file_handle := win.CreateFileW(file_path_w, dwDesiredAccess, dwShareMode, nil, u32(dwCreationDisposition), dwFlagsAndAttributes, nil)
	if file_handle != win.INVALID_HANDLE_VALUE {
		win_stats: win.BY_HANDLE_FILE_INFORMATION
		win.GetFileInformationByHandle(file_handle, &win_stats)
		file = File {
			file_handle,
			0,
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
read_file :: proc(file: ^File, buffer: []byte) -> (total_read_byte_count: int) {
	buffer_ptr := raw_data(buffer)
	n := len(buffer)
	for n > 0 {
		bytes_to_read_u32 := min(u32(n), max(u32))
		read_byte_count_word: win.DWORD
		win.ReadFile(file.handle, buffer_ptr, bytes_to_read_u32, &read_byte_count_word, nil)
		read_byte_count := int(read_byte_count_word)
		if read_byte_count == 0 {break}

		buffer_ptr = math.ptr_add(buffer_ptr, read_byte_count)
		n -= read_byte_count
	}
	total_read_byte_count = len(buffer) - n
	file.offset += total_read_byte_count
	return
}
write_file :: proc(file: ^File, buffer: []byte, loc := #caller_location) {
	buffer_ptr := raw_data(buffer)
	n := len(buffer)
	for n > 0 {
		bytes_to_write_u32 := min(u32(n), max(u32))
		written_byte_count_word: win.DWORD
		win.WriteFile(file.handle, raw_data(buffer), bytes_to_write_u32, &written_byte_count_word, nil)
		written_byte_count := int(written_byte_count_word)
		assert(written_byte_count > 0, loc = loc)

		buffer_ptr = math.ptr_add(buffer_ptr, written_byte_count)
		n -= written_byte_count
	}
	file.offset += len(buffer)
}
read_file_at :: proc(file: ^File, buffer: []byte, offset: int) {
	// NOTE: we have to emulate pread() by moving the file pointer on Windows..
	offset_low := i32(offset)
	offset_high := i32(offset >> 32)
	file.offset = offset
	win.SetFilePointer(file.handle, offset_low, &offset_high, win.FILE_BEGIN)

	read_file(file, buffer)
}
write_file_at :: proc(file: ^File, buffer: []byte, offset: int, loc := #caller_location) {
	// NOTE: we have to emulate pwrite() by moving the file pointer on Windows..
	offset_low := i32(offset)
	offset_high := i32(offset >> 32)
	file.offset = offset
	win.SetFilePointer(file.handle, offset_low, &offset_high, win.FILE_BEGIN)

	write_file(file, buffer, loc = loc)
}
flush_file :: proc(file: File) {
	win.FlushFileBuffers(file.handle)
}
