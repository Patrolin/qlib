package os_utils
import "base:intrinsics"
import "base:runtime"
import "core:strings"
import "core:sys/linux"
import "core:sys/unix"

// types
linux_Stat :: linux.Stat
linux_Statx :: linux.Statx
FileHandle :: linux.Fd

// common procedures
init :: #force_inline proc "contextless" () -> runtime.Context {
	ctx := empty_context()
	return ctx
}

// helper functions
linux_S_IFDIR :: 0x4000

// string procedures
linux_string_to_cstring :: proc(str: string, allocator := context.temp_allocator) -> cstring {
	return strings.clone_to_cstring(str, allocator = allocator)
}
linux_cstring_to_string :: #force_inline proc(cstr: cstring) -> string {
	return string(cstr)
}

// syscalls helpers
@(private)
syscall0 :: #force_inline proc(id: uintptr) -> int {
	return int(intrinsics.syscall(id))
}
@(private)
syscall1 :: #force_inline proc(id: uintptr, #any_int a: uintptr) -> int {
	return int(intrinsics.syscall(id, a))
}
@(private)
syscall2 :: #force_inline proc(id: uintptr, #any_int a, b: uintptr) -> int {
	return int(intrinsics.syscall(id, a, b))
}
@(private)
syscall3 :: #force_inline proc(id: uintptr, #any_int a, b, c: uintptr) -> int {
	return int(intrinsics.syscall(id, a, b, c))
}
@(private)
syscall4 :: #force_inline proc(id: uintptr, #any_int a, b, c, d: uintptr) -> int {
	return int(intrinsics.syscall(id, a, b, c, d))
}
@(private)
syscall5 :: #force_inline proc(id: uintptr, #any_int a, b, c, d, e: uintptr) -> int {
	return int(intrinsics.syscall(id, a, b, c, d, e))
}
@(private)
syscall6 :: #force_inline proc(id: uintptr, #any_int a, b, c, d, e, f: uintptr) -> int {
	return int(intrinsics.syscall(id, a, b, c, d, e, f))
}
@(private)
get_result :: #force_inline proc(result: int) -> linux.Errno {
	return linux.Errno(-result)
}
@(private)
get_result_maybe :: #force_inline proc(result: int, $T: typeid) -> (value: T, errno: linux.Errno) {
	if intrinsics.expect(result < 0, false) {
		errno = linux.Errno(-result)
	} else {
		value = (T)(result)
	}
	return
}

// stat syscalls
NewFStatAtFlags :: enum int {
	AT_SYMLINK_NOFOLLOW = 0x0100,
	AT_SYMLINK_FOLLOW   = 0x0400,
	AT_NO_AUTOMOUNT     = 0x0800,
	AT_EMPTY_PATH       = 0x1000,
}
@(require_results)
linux_newfstatat :: proc(dir: FileHandle, path: cstring, stat: ^linux_Stat, flags: i32) -> linux.Errno {
	result := syscall4(linux.SYS_newfstatat, dir, rawptr(path), stat, flags)
	return get_result(result)
}
@(require_results)
linux_stat :: proc(path: cstring, stat: ^linux_Stat) -> linux.Errno {
	return linux_newfstatat(linux.AT_FDCWD, path, stat, 0)
}
@(require_results)
linux_fstat :: proc(fd: FileHandle, stat: ^linux_Stat) -> linux.Errno {
	return linux_newfstatat(fd, "", stat, i32(NewFStatAtFlags.AT_EMPTY_PATH))
}
@(require_results)
linux_statx :: proc(dir: FileHandle, path: cstring, flags: i32, mask: u32, statx: ^linux_Statx) -> linux.Errno {
	result := syscall5(linux.SYS_statx, dir, rawptr(path), flags, mask, statx)
	return get_result(result)
}

// dir syscalls
@(require_results)
linux_mkdir :: proc(path: cstring, mode: uint = 0o000) -> linux.Errno {
	result := syscall2(linux.SYS_mkdir, rawptr(path), mode)
	return get_result(result)
}
@(require_results)
linux_rmdir :: proc(path: cstring) -> linux.Errno {
	result := syscall1(linux.SYS_rmdir, rawptr(path))
	return get_result(result)
}
@(require_results)
linux_fsync :: proc(fd: FileHandle) -> linux.Errno {
	result := syscall1(linux.SYS_fsync, fd)
	return get_result(result)
}

// open file syscalls
@(require_results)
linux_open :: proc(path: cstring, flags: int, mode: uint = 0o000) -> (fd: FileHandle, errno: linux.Errno) {
	result := syscall3(linux.SYS_open, rawptr(path), flags, mode)
	return get_result_maybe(result, FileHandle)
}
@(require_results)
linux_read :: proc(fd: FileHandle, buffer: rawptr, #any_int size: uint) -> (read_count: int) {
	return syscall3(linux.SYS_read, fd, buffer, size)
}
@(require_results)
linux_write :: proc(fd: FileHandle, buffer: rawptr, #any_int size: uint) -> (written_count: int) {
	return syscall3(linux.SYS_write, fd, buffer, size)
}
@(require_results)
linux_pread :: proc(fd: FileHandle, buffer: rawptr, #any_int size: uint, #any_int offset: i64) -> (read_count: int) {
	return syscall4(linux.SYS_pread64, fd, buffer, size, offset)
}
@(require_results)
linux_pwrite :: proc(fd: FileHandle, buffer: rawptr, #any_int size: uint, #any_int offset: i64) -> (written_count: int) {
	return syscall4(linux.SYS_pwrite64, fd, buffer, size, offset)
}

// close file syscalls
/* NOTE: linux_fsync() is under dir procs */
@(require_results)
linux_close :: proc(fd: FileHandle) -> linux.Errno {
	result := syscall1(linux.SYS_close, fd)
	return get_result(result)
}
@(require_results)
linux_unlink :: proc(path: cstring) -> linux.Errno {
	result := syscall1(linux.SYS_unlink, rawptr(path))
	return get_result(result)
}
@(require_results)
linux_rename :: proc(old, new: cstring) -> linux.Errno {
	result := syscall2(linux.SYS_rename, rawptr(old), rawptr(new))
	return get_result(result)
}
