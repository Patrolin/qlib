package lib_alloc
import "../fmt"
import "../os"
import "base:intrinsics"
import "base:runtime"

// types
DBColumn :: struct($T: typeid) {
	file_view: os.FileView,
}

// procedures
create_table :: proc(table: ^$T) where intrinsics.type_is_struct(T) {
	os.new_directory("db")

	table_named_info := type_info_of(T).variant.(runtime.Type_Info_Named)
	table_name := table_named_info.name
	table_struct_info := table_named_info.base.variant.(runtime.Type_Info_Struct)
	for i in 0 ..< table_struct_info.field_count {
		type := table_struct_info.types[i]
		name := table_struct_info.names[i]
		offsets := table_struct_info.offsets[i]
		fmt.printfln("type: %v", type)
		// TODO!
	}

	/*
	for &column in columns {
		file_path := fmt.tprintf("db/%v", column.name)
		file_view, ok := os.open_file_view(file_path)
		fmt.assertf(ok, "Failed to open file %v", file_path)
		column.file_view = file_view
	}
	*/
}
