package lib_path
import "../fmt"

read_save_file :: proc(file_path: string) -> (data: string, ok: bool) {
	return read_entire_file(file_path)
}
write_save_file :: proc(file_path: string, data: string) {
	tmp_file_path := fmt.tprintf("%v.tmp", file_path)
	assert(write_entire_file(tmp_file_path, data))
	assert(move_path_atomically(tmp_file_path, file_path))
}
