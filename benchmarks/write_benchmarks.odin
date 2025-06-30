package benchmarks
import odin_os "core:os"
import win "core:sys/windows"

// constants
FILE_PATH :: "benchmarks/data/file.txt"
// globals
file_to_write := ""

// procedures
delete_file :: proc() {
	odin_os.remove(FILE_PATH)
}
write_file :: proc(file_path: string, data: []byte) {
	when ODIN_OS == .Windows {
		file_path_w := win.utf8_to_wstring(FILE_PATH)
		security_attributes := win.SECURITY_ATTRIBUTES {
			nLength        = size_of(win.SECURITY_ATTRIBUTES),
			bInheritHandle = true,
		}
		file := win.CreateFileW(
			file_path_w,
			win.GENERIC_WRITE,
			win.FILE_SHARE_READ | win.FILE_SHARE_WRITE,
			&security_attributes,
			win.CREATE_ALWAYS,
			win.FILE_ATTRIBUTE_NORMAL,
			nil,
		)
		win.WriteFile(file, raw_data(data), u32(len(data)), nil, nil)
	} else {
		#assert(false, "not implemented")
	}
}

// benchmarks
write_by_odin_stdlib :: proc() {
	err := odin_os.write_entire_file_or_err(FILE_PATH, transmute([]u8)(file_to_write))
	assert(err == nil)
}
write_by_syscall :: proc() {
	write_file(FILE_PATH, transmute([]u8)file_to_write)
}
