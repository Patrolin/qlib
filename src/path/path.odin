package lib_path
import "../fmt"
import "../os"

// types
PathType :: enum {
	None,
	File,
	Directory,
}
FileOptionsEnum :: enum {
	ReadOnly,
	WriteOnly,
	// Must create a new file, don't open if it already exists.
	CreateOnly,
	Truncate,
	// NOTE: requires read/writes to be aligned to bytesPerSector (512B)
	NoBuffering,
	// windows hint
	UniqueAccess,
	// windows hint
	RandomAccess,
	// O_DSYNC on linux, FILE_FLAG_WRITE_THROUGH on windows
	FlushOnWrite,
}
FileOptions :: bit_set[FileOptionsEnum]
File :: struct {
	handle:          os.FileHandle,
	size:            int,
	last_write_time: int,
}

// helper procedures
@(private)
_assert_path_is_safe_to_delete :: #force_inline proc(path: string) {
	#no_bounds_check {
		assert(len(path) >= 2)
		assert((path[0] != '~' && path[1] != ':') || len(path) >= 4)
	}
}

// procedures
read_entire_file :: proc(file_path: string, allocator := context.temp_allocator) -> (data: string, ok: bool) {
	file := open_file(file_path, {.ReadOnly}) or_return
	buffer := make([]byte, file.size, allocator = allocator)
	assert(read_file(&file, buffer) == file.size)
	close_file(file.handle)
	return transmute(string)buffer, true
}
write_entire_file :: proc(file_path: string, data: string) -> (ok: bool) {
	file := open_file(file_path, {.WriteOnly, .Truncate}) or_return
	write_file(&file, transmute([]u8)data)
	flush_file(file.handle) // NOTE: make sure the data is written to disk immediately
	close_file(file.handle)
	return true
}
write_entire_file_atomically :: proc(file_path: string, data: string) {
	tmp_file_path := fmt.tprintf("%v.tmp", file_path)
	assert(write_entire_file(tmp_file_path, data))
	assert(move_path_atomically(tmp_file_path, file_path))
}
