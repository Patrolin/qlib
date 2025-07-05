package lib_mem_types
import "../../fmt"
import "../../math"
import "../../os"
import "base:intrinsics"
import "base:runtime"
import "core:strings"

// types
DBColumn :: struct($T: typeid) {
	file_view: os.FileView,
}

// procedures
create_table :: proc(table: ^$T) where intrinsics.type_is_struct(T) {
	table_named_info := type_info_of(T).variant.(runtime.Type_Info_Named)
	table_name := table_named_info.name
	os.new_directory("db")
	os.new_directory(fmt.tprintf("db/%v", table_name))

	table_struct_info := table_named_info.base.variant.(runtime.Type_Info_Struct)
	for i in 0 ..< table_struct_info.field_count {
		named_info := table_struct_info.types[i].variant.(runtime.Type_Info_Named) or_continue
		field_name := table_struct_info.names[i]
		field_offset := table_struct_info.offsets[i]
		is_db_column := strings.starts_with(named_info.name, "DBColumn(")
		if !is_db_column {continue}
		db_column := (^DBColumn(any))(math.ptr_add(table, int(field_offset)))

		file_view, ok := os.open_file_view(fmt.tprintf("db/%v/%v.bin", table_name, field_name))
		fmt.assertf(ok, "Failed to create file_view for %v, %v", field_name, db_column)
		db_column.file_view = file_view
	}
}
