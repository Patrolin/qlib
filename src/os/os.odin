package os_utils
import "../math"
import "base:runtime"

// globals
info: OsInfo

// types
OsInfo :: struct {
	duration_multiplier: i64,
	page_size:           int,
	large_page_size:     int,
	logical_core_count:  int,
	window_border:       math.AbsoluteRect,
}
PathType :: enum {
	None,
	File,
	Directory,
}
FileOptionsEnum :: enum {
	ReadOnly,
	WriteOnly,
	OnlyCreate,
	Truncate,
	// windows hint
	UniqueAccess,
	// windows hint
	RandomAccess,
	// O_DSYNC on linux, TODO: emulated on windows
	FlushOnWrite,
}
FileOptions :: bit_set[FileOptionsEnum]

// helper procedures
@(private)
assert_path_is_safe_to_delete :: #force_inline proc(path: string) {
	#no_bounds_check {
		assert(len(path) >= 2)
		assert((path[0] != '~' && path[1] != ':') || len(path) >= 4)
	}
}

// procedures
empty_context :: #force_inline proc "contextless" () -> runtime.Context {
	return runtime.Context{assertion_failure_proc = runtime.default_assertion_failure_proc}
}

read_entire_file :: proc(file_path: string, allocator := context.temp_allocator) -> (data: string, ok: bool) {
	file := open_file(file_path, {.ReadOnly}) or_return
	buffer := make([]byte, file.size, allocator = allocator)
	read_file(&file, buffer)
	close_file(file)
	return transmute(string)buffer, true
}
write_entire_file :: proc(file_path: string, data: string) -> (ok: bool) {
	file := open_file(file_path, {.WriteOnly, .Truncate}) or_return
	write_file(&file, transmute([]u8)data)
	close_file(file)
	return true
}
