package lib_mem_types
import "../../os"

read_save_file :: proc(file_path: string) -> (data: string, ok: bool) {
	file_type := os.get_path_type(file_path)
	if file_type == .File {
		return os.read_entire_file(file_path)
	} else {
		return "", false
	}
}
write_save_file :: proc(file_path: string, data: string) {

}
