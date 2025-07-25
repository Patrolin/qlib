package lib_path
import "../math"
import "../os"
import "../timing"
import "base:intrinsics"
import "core:strings"
import "core:sys/unix"

// constants
@(private)
OpenFlags :: enum {
	O_RDONLY    = 0x000000, // NOTE: linux will happily open a file with O_RDONLY|O_WRONLY, :shrug:
	O_WRONLY    = 0x000001,
	O_RDWR      = 0x000002,
	// RESERVED      = 0x000004,
	// RESERVED      = 0x000008,
	// RESERVED      = 0x000010,
	// RESERVED      = 0x000020,
	O_CREAT     = 0x000040,
	O_EXCL      = 0x000080,
	O_NOCTTY    = 0x000100,
	O_TRUNC     = 0x000200,
	O_APPEND    = 0x000400,
	O_NONBLOCK  = 0x000800,
	O_DSYNC     = 0x001000,
	O_ASYNC     = 0x002000,
	O_DIRECT    = 0x004000,
	O_LARGEFILE = 0x008000,
	O_DIRECTORY = 0x010000,
	O_NOFOLLOW  = 0x020000,
	O_NOATIME   = 0x040000,
	O_CLOEXEC   = 0x080000, // TODO: do we want to use this?
	O_SYNC      = 0x101000,
	O_PATH      = 0x200000,
	O_TMPFILE   = 0x400000,
}

// types
FileHandle :: distinct i32
File :: struct {
	handle:          FileHandle,
	size:            int,
	last_write_time: int,
}
FileView :: struct {
	file: File,
	data: []byte `fmt:"-"`,
}

// path procedures
move_path_atomically :: proc(old_path: string, new_path: string) -> (ok: bool) {
	old_cpath := os.linux_string_to_cstring(old_path)
	new_cpath := os.linux_string_to_cstring(new_path)
	err := unix.sys_rename(old_cpath, new_cpath)
	if intrinsics.expect(err != 0, false) {return false}
	// fsync the parent directory
	last_slash_index := strings.last_index(new_path, "/")
	dir_path := last_slash_index == -1 ? "." : new_path[:last_slash_index]
	dir_cpath := os.linux_string_to_cstring(dir_path)
	dir_handle := unix.sys_open(dir_cpath, int(OpenFlags.O_DIRECTORY), 0)
	assert(unix.sys_fsync(dir_handle) == 0)
	return true
}
get_path_type :: proc(path: string) -> (path_type: PathType) {
	path_info: os.linux_Stat
	err := unix.sys_stat(os.linux_string_to_cstring(path), &path_info)
	path_type = (transmute(u32)(path_info.mode) & os.linux_S_IFDIR == os.linux_S_IFDIR) ? .Directory : .File
	path_type = err == 0 ? path_type : .None
	return
}
delete_path_recursively :: proc(path: string) {
	_assert_path_is_safe_to_delete(path)
	path_type := get_path_type(path)
	switch path_type {
	case .None:
	case .File:
		delete_file(path)
	case .Directory:
		assert(false, "Not implemented")
	}
}

// dir procedures
delete_directory_if_empty :: proc(dir_path: string) {
	unix.sys_rmdir(os.linux_string_to_cstring(dir_path))
}
new_directory :: proc(dir_path: string) -> (ok: bool) {
	err := unix.sys_mkdir(os.linux_string_to_cstring(dir_path), 0o744)
	return err == 0
}

// file procedures
delete_file :: proc(file_path: string) {
	unix.sys_unlink(os.linux_string_to_cstring(file_path))
}
open_file :: proc(file_path: string, options: FileOptions) -> (file: File, ok: bool) {
	cfile_path := os.linux_string_to_cstring(file_path)
	read_only := options >= {.ReadOnly}
	write_only := options >= {.WriteOnly}

	open_flags := OpenFlags.O_LARGEFILE | OpenFlags.O_NOATIME
	open_flags |= read_only ? {} : OpenFlags.O_CREAT
	open_flags |= read_only ? {} : (write_only ? OpenFlags.O_WRONLY : OpenFlags.O_RDWR)
	open_flags |= options >= {.NoOpen} ? OpenFlags.O_EXCL : {}
	open_flags |= options >= {.Truncate} ? OpenFlags.O_TRUNC : {}
	open_flags |= options >= {.NoBuffering} ? OpenFlags.O_DIRECT : {}
	open_flags |= options >= {.FlushOnWrite} ? OpenFlags.O_DSYNC : {}

	file_handle := FileHandle(unix.sys_open(cfile_path, int(open_flags), 0o744))
	if file_handle != 0 {
		stat: os.linux_Stat
		unix.sys_fstat(int(file_handle), &stat)
		file = File{file_handle, int(stat.size), int(stat.atime.time_sec) * int(timing.SECOND) + int(stat.atime.time_nsec)}
		ok = true
	}
	return
}
flush_file :: proc(file_handle: FileHandle) {
	unix.sys_fsync(int(file_handle))
}
close_file :: proc(file_handle: FileHandle) {
	assert(unix.sys_close(int(file_handle)) == 0)
}

// read/write file procs
@(require_results)
read_file :: proc(file: ^File, buffer: []byte) -> (total_read_byte_count: int) {
	buffer_ptr := raw_data(buffer)
	n := len(buffer)
	for n > 0 {
		read_byte_count := unix.sys_read(int(file.handle), buffer_ptr, uint(n))
		if read_byte_count <= 0 {break}

		n -= read_byte_count
		buffer_ptr = math.ptr_add(buffer_ptr, read_byte_count)
	}
	total_read_byte_count = len(buffer) - n
	return
}
write_file :: proc(file: ^File, buffer: []byte, loc := #caller_location) {
	buffer_ptr := raw_data(buffer)
	n := len(buffer)
	for n > 0 {
		written_byte_count := unix.sys_write(int(file.handle), buffer_ptr, uint(n))
		assert(written_byte_count > 0, loc = loc)

		n -= written_byte_count
		buffer_ptr = math.ptr_add(buffer_ptr, written_byte_count)
	}
}
@(require_results)
read_file_at :: proc(file: ^File, buffer: []byte, offset: int) -> (total_read_byte_count: int) {
	buffer_ptr := raw_data(buffer)
	n := len(buffer)
	for n > 0 {
		read_byte_count := unix.sys_pread(int(file.handle), buffer_ptr, uint(n), i64(offset))
		if read_byte_count <= 0 {break}

		n -= read_byte_count
		buffer_ptr = math.ptr_add(buffer_ptr, read_byte_count)
	}
	total_read_byte_count = len(buffer) - n
	return
}
write_file_at :: proc(file: ^File, buffer: []byte, offset: int, loc := #caller_location) {
	buffer_ptr := raw_data(buffer)
	n := len(buffer)
	for n > 0 {
		written_byte_count := unix.sys_pwrite(int(file.handle), buffer_ptr, uint(n), i64(offset))
		assert(written_byte_count > 0, loc = loc)

		n -= written_byte_count
		buffer_ptr = math.ptr_add(buffer_ptr, written_byte_count)
	}
}
