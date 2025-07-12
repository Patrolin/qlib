package os_utils
import "../fmt"
import "../timing"
import "core:os"
import "core:strings"
import "core:sys/linux"
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
FileHandle :: linux.Fd
File :: struct {
	handle:          FileHandle,
	size:            int,
	last_write_time: int,
}
FileView :: struct {
	file: File,
	data: []byte `fmt:"-"`,
}

// string procedures
@(private)
linux_string_to_cstring :: proc(str: string, allocator := context.temp_allocator) -> cstring {
	return strings.clone_to_cstring(str, allocator = allocator)
}
@(private)
linux_cstring_to_string :: #force_inline proc(cstr: cstring) -> string {
	return string(cstr)
}

// path procedures
move_path :: proc(old_path: string, new_path: string) -> (ok: bool) {
	err := linux.rename(linux_string_to_cstring(old_path), linux_string_to_cstring(new_path))
	return err == nil
}
get_path_type :: proc(path: string) -> (path_type: PathType) {
	path_info: linux.Stat
	err := linux.stat(linux_string_to_cstring(path), &path_info)
	path_type = linux.S_ISDIR(path_info.mode) ? .Directory : .File
	path_type = err != nil ? .None : path_type
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
		assert(false, "Not implemented")
	}
}

// dir procedures
delete_directory_if_empty :: proc(dir_path: string) {
	linux.rmdir(linux_string_to_cstring(dir_path))
}
new_directory :: proc(dir_path: string) -> (ok: bool) {
	err := unix.sys_mkdir(linux_string_to_cstring(dir_path), 0o744)
	return err == 0
}

// file procedures
delete_file :: proc(file_path: string) {
	linux.unlink(linux_string_to_cstring(file_path))
}
open_file :: proc(file_path: string, options: FileOptions) -> (file: File, ok: bool) {
	cfile_path := linux_string_to_cstring(file_path)
	read_only := options >= {.ReadOnly}
	write_only := options >= {.WriteOnly}

	open_flags := OpenFlags.O_LARGEFILE | OpenFlags.O_NOATIME
	open_flags |= read_only ? {} : OpenFlags.O_CREAT
	open_flags |= read_only ? {} : (write_only ? OpenFlags.O_WRONLY : OpenFlags.O_RDWR)
	open_flags |= options >= {.DontOpenExisting} ? OpenFlags.O_EXCL : {}
	open_flags |= options >= {.Truncate} ? OpenFlags.O_TRUNC : {}
	open_flags |= options >= {.FlushOnWrite} ? OpenFlags.O_DSYNC : {}

	file_handle := FileHandle(unix.sys_open(cfile_path, int(open_flags), 0o744))
	if file_handle != 0 {
		stat: linux.Stat
		unix.sys_fstat(int(file_handle), &stat)
		file = File{file_handle, int(stat.size), int(stat.atime.time_sec) * int(timing.SECOND) + int(stat.atime.time_nsec)}
		ok = true
	}
	return
}
close_file :: proc(file: File) {
	assert(linux.close(file.handle) == nil)
}
read_file_2 :: proc(file_handle: FileHandle, buffer: []byte) {
	for i := 0; i < len(buffer); {
		read_byte_count, _ := linux.read(file_handle, buffer[i:])
		i += read_byte_count
	}
}
write_file_2 :: proc(file_handle: FileHandle, buffer: []byte) {
	for i := 0; i < len(buffer); {
		written_byte_count, _ := linux.write(file_handle, buffer[i:])
		i += written_byte_count
	}
}
flush_file :: proc(file_handle: FileHandle) {
	linux.fsync(file_handle)
}

// TODO: use pwrite() instead of mmap()

// file_view procedures
open_file_view :: proc(file_view: ^FileView, new_size: int) -> (ok: bool) {
	assert(file_view.file.handle != 0)
	if file_view.file.size != new_size {
		linux.ftruncate(file_view.file.handle, i64(new_size))
	}
	file_view.file.size = new_size
	// reopen the file_view
	ptr, err := linux.mmap(0, uint(new_size), {.READ, .WRITE}, {.PRIVATE}, file_view.file.handle, 0)
	file_view.data = ([^]byte)(ptr)[:new_size]
	return err == nil
}
close_file_view :: proc(file_view: FileView) {
	err := linux.munmap(raw_data(file_view.data), len(file_view.data))
	assert(err == nil)
}
resize_file_view :: proc(file_view: ^FileView, new_size: int) -> (ok: bool) {
	close_file_view(file_view^)
	// set the file size
	if file_view.file.size != new_size {
		linux.ftruncate(file_view.file.handle, i64(new_size))
	}
	file_view.file.size = new_size
	// reopen the file_view
	ptr, err := linux.mmap(0, uint(new_size), {.READ, .WRITE}, {.PRIVATE}, file_view.file.handle, 0)
	file_view.data = ([^]byte)(ptr)[:new_size]
	return err == nil
}
