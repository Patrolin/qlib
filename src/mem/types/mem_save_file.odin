package lib_mem_types
import "../../fmt"
import "../../os"

read_save_file :: proc(file_path: string) -> (data: string, ok: bool) {
	data, ok = os.read_entire_file(file_path)
	if ok {return}

	old_file_path := fmt.tprintf("%v.old", file_path)
	data, ok = os.read_entire_file(old_file_path)
	if ok {return}

	return "", false
}
write_save_file :: proc(file_path: string, data: string) {
	old_file_path := fmt.tprintf("%v.old", file_path)
	tmp_file_path := fmt.tprintf("%v.tmp", file_path)
	// backup the existing file
	if os.get_path_type(file_path) == .File {
		os.delete_path_recursively(old_file_path)
		assert(os.move_path(file_path, old_file_path))
	}
	// make a new file
	os.delete_path_recursively(tmp_file_path)
	assert(os.write_entire_file(tmp_file_path, data))
	// commit the file
	assert(os.move_path(tmp_file_path, file_path))
	os.delete_path_recursively(old_file_path)
}
