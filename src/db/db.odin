package lib_db
import "../fmt"
import "../math"
import "../mem/types"
import "../path"
import "../strings"
import "base:intrinsics"
import "base:runtime"

/* NOTE: for GDPR deletion requests
	- soft delete and anonymize the user
	- run on_delete(row) (on delete, and on startup if deletion_version mismatch)
*/
Table :: struct($Row: typeid) where intrinsics.type_is_struct(Row) {
	_row_type: ^Row,
	on_delete: proc(row: rawptr),
	file:      path.File,
	file_name: string,
}

open_database :: proc(database: $P/^$Database, database_dir_path := "db") {
	// create a directory at `database_dir_path`
	path.new_directory(database_dir_path)
	// for each table: open the table, apply write ahead log, apply migrations
	database_type := type_info_of(Database).variant.(runtime.Type_Info_Named).base.variant.(runtime.Type_Info_Struct)
	for i in 0 ..< database_type.field_count {
		table_type := database_type.types[i].variant.(runtime.Type_Info_Named).base.variant.(runtime.Type_Info_Struct)
		table_type_string := fmt.tprint(database_type.types[i])
		assert(strings.starts_with(table_type_string, "Table("))
		row_type_named := table_type.types[0].variant.(runtime.Type_Info_Pointer).elem
	}
	for i in 0 ..< database_type.field_count {
		table_name := database_type.names[i]
		table_offset := int(database_type.offsets[i])
		table_type := database_type.types[i].variant.(runtime.Type_Info_Named).base.variant.(runtime.Type_Info_Struct)
		row_type_named := table_type.types[0].variant.(runtime.Type_Info_Pointer).elem

		table := (^Table(types.void))(math.ptr_add(database, table_offset))
		_open_table(table, database_dir_path, table_name, row_type_named)
	}
	for i in 0 ..< database_type.field_count {
		// TODO: apply_write_ahead_log(table, table_name, row_type_named)
	}
	for i in 0 ..< database_type.field_count {
		// TODO: apply_migrations(table, table_name, row_type_named)
	}
}
@(private)
_open_table :: proc(
	table: ^Table(types.void),
	database_dir_path, table_name: string,
	row_type_named: ^runtime.Type_Info,
	loc := #caller_location,
) {
	table_file_name := fmt.tprintf("%v/%v.bin", database_dir_path, table_name)
	table.file_name = table_file_name
	file, ok := path.open_file(table_file_name, {.UniqueAccess, .RandomAccess, .NoBuffering, .FlushOnWrite})
	fmt.assertf(ok, "Failed to open file: %v", table_file_name)
	table.file = file
}
set_on_delete :: proc(database: ^$Database, key: string, deletion_version: int, on_delete: proc(row: rawptr)) {
	// TODO: assert that row has deletion_version as second field, handle incomplete deletions and set on_delete
}
