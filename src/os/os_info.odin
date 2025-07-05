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
FileOptionsEnum :: enum {
	Read,
	Write_Truncate,
	Write_Preserve,
	UniqueAccess,
}
FileOptions :: bit_set[FileOptionsEnum]

// procedures
empty_context :: #force_inline proc "contextless" () -> runtime.Context {
	return runtime.Context{assertion_failure_proc = runtime.default_assertion_failure_proc}
}
read_entire_file :: proc(file_path: string, allocator := context.temp_allocator) -> (data: string, ok: bool) {
	file := open_file(file_path, {.Read}) or_return
	buffer := make([]byte, file.file_size, allocator = allocator)
	n := 0
	for n < len(buffer) {n += read_file(file.handle, buffer[n:])}
	close_file(file)
	return transmute(string)buffer, true
}
write_entire_file :: proc(file_path: string, data: string) -> (ok: bool) {
	file := open_file(file_path, {.Write_Truncate}) or_return
	data_bytes := transmute([]u8)data
	for n := 0; n < len(data); {n += write_file(file.handle, data_bytes[n:])}
	close_file(file)
	return true
}
