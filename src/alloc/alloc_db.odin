package lib_alloc
import "../fmt"
import "../os"

// types
DBColumn :: struct {
	name: string,
	type: typeid,
	file: os.File,
}

// procedures
create_db :: proc(columns: []DBColumn) {
	for &column in columns {
		file_path := fmt.tprintf("db/%v", column.name)
		file, ok := os.create_file(file_path, {.Read, .Write, .PreserveFile, .UniqueAccess})
		fmt.assertf(ok, "Failed to open file %v", file_path)
		column.file = file
	}
}
