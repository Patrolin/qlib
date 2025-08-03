package lib_path
import "../fmt"
import "../math"
import "../mem"
import "../mem/types"
import "../path"
import "base:intrinsics"
import "base:runtime"
import "core:strings"

// NOTE: a row_id always refers to the same row (until you hard delete that row)

/* TODO: automatic migrations when fields change (allow new/rename/drop via tags)
	Foo :: struct {
		name: string `v1:+`,
		score:   i32 `v1:+`,
		foo:     f64 `v1:+`,
	}

	Foo :: struct {
		user_name: string `v1:+ v2:/name -foo`,
		score:   i32 `v1:+`,
		bar:     f32 `v2:+`,
	}
*/

/* TODO: write ahead log for consistency?
	- have multiple sequentially written files
		- fsync(file); fsync(dir) ahead of time
	- have a checksum for each entry
*/

// TODO: BTree(hash(field), id) indexes for fast filter/sort

// constants
TABLE_ROW_SIZE :: 512

// types
Table :: struct($T: typeid) where intrinsics.type_is_struct(T) {
	_row_type:      ^T `fmt:"-"`,
	file:           File,
	data_lock:      mem.Lock,
	data_row_count: int,
	header:         TableHeader,
}

// procedures
open_database :: proc(database: ^$T) where intrinsics.type_is_struct(T) {
	// make directory
	path.new_directory("db")
	// for each table field
	database_type := type_info_of(T).variant.(runtime.Type_Info_Named).base.variant.(runtime.Type_Info_Struct)
	for i in 0 ..< database_type.field_count {
		table_name := database_type.names[i]
		table_offset := int(database_type.offsets[i])
		table_type := database_type.types[i].variant.(runtime.Type_Info_Named).base.variant.(runtime.Type_Info_Struct)
		table_type_string := fmt.tprint(database_type.types[i])
		assert(strings.starts_with(table_type_string, "Table("))
		row_type_named := table_type.types[0].variant.(runtime.Type_Info_Pointer).elem
		// open table
		table := (^Table(types.void))(math.ptr_add(database, table_offset))
		_open_table(table, table_name, row_type_named)
		_migrate_table(table, table_name, row_type_named)
	}
}

insert_table_row :: proc(table: ^Table($T), value: ^T) -> (ok: bool) {
	mem.get_lock(&table.data_lock)
	defer mem.release_lock(&table.data_lock)
	// get table name
	named_info := type_info_of(T).variant.(runtime.Type_Info_Named)
	// get appropriate row
	row_id := (^int)(value)^
	row: DBTableRow
	if intrinsics.expect(row_id < 0 || row_id > int(table.header.last_used_row_id), false) {return false}
	if row_id == 0 {
		row_id = _get_new_table_row(table, &row)
	}
	row.used = true
	// copy the id
	row_data_base_ptr := ([^]byte)(&row.data)
	(^u64le)(row_data_base_ptr)^ = u64le(row_id)
	row_data_offset := 8
	// copy the fields
	struct_info := named_info.base.variant.(runtime.Type_Info_Struct)
	for i in 1 ..< struct_info.field_count {
		//field_name := struct_info.names[i]
		field_offset := int(struct_info.offsets[i])
		field_type := struct_info.types[i]
		field_size := field_type.size
		field_ptr := math.ptr_add(value, field_offset)

		//fmt.printfln("field, `%v: %v` at %v (%v B)", field_name, field_type, field_offset, field_size)
		#partial switch field in field_type.variant {
		case runtime.Type_Info_Boolean, runtime.Type_Info_Integer, runtime.Type_Info_Float:
			if intrinsics.expect(row_data_offset + field_size > TABLE_ROW_DATA_SIZE, false) {return false}
			switch field_size {
			case 1:
				(^u8)(&row_data_base_ptr[row_data_offset])^ = (^u8)(field_ptr)^
			case 2:
				(^u16le)(&row_data_base_ptr[row_data_offset])^ = u16le((^u16)(field_ptr)^)
			case 4:
				(^u32le)(&row_data_base_ptr[row_data_offset])^ = u32le((^u32)(field_ptr)^)
			case 8:
				(^u64le)(&row_data_base_ptr[row_data_offset])^ = u64le((^u64)(field_ptr)^)
			case:
				fmt.assertf(false, "Not implemented: %v", field_type)
			}
			row_data_offset += field_size
		case runtime.Type_Info_Array:
			if intrinsics.expect(row_data_offset + field_size > TABLE_ROW_DATA_SIZE, false) {return false}
			for j in 0 ..< field_size {
				row_data_base_ptr[row_data_offset + j] = field_ptr[field_offset + j]
			}
			row_data_offset += field_size
		case runtime.Type_Info_String:
			{
				string_value_ptr := transmute(^runtime.Raw_String)(field_ptr)
				string_value := string_value_ptr^
				string_buffer := string_value.data
				string_length := string_value.len
				if intrinsics.expect(row_data_offset + 8 + string_length > TABLE_ROW_DATA_SIZE, false) {return false}

				(^u64le)(&row_data_base_ptr[row_data_offset])^ = u64le(string_length)
				row_data_offset += 8

				for j in 0 ..< string_length {
					row_data_base_ptr[row_data_offset + j] = string_buffer[j]
				}
				row_data_offset += string_length
			}
		case:
			fmt.assertf(false, "Not implemented, %v: %v", struct_info.names[i], field_type)
		}
	}
	_write_table_row(&table.file, &row, row_id)
	// update `data_row_count` and flush file
	table.data_row_count += 1
	return true
}

get_table_row :: proc(table: ^Table($T), id: int, value: ^T, allocator := context.temp_allocator) -> (ok: bool) {
	named_info := type_info_of(T).variant.(runtime.Type_Info_Named)
	// get the slot
	row: DBTableRow
	if intrinsics.expect(id <= 0, false) {
		value^ = {}
		return false
	}
	read_ok := _read_table_row(&table.file, &row, id)
	if !read_ok || !row.used {
		value^ = {}
		return false
	}
	// copy the data
	row_data_ptr := ([^]byte)(&row.data)
	struct_info := named_info.base.variant.(runtime.Type_Info_Struct)
	for i in 0 ..< struct_info.field_count {
		//field_name := struct_info.names[i]
		field_offset := int(struct_info.offsets[i])
		field_type := struct_info.types[i]
		field_size := field_type.size
		field_ptr := math.ptr_add(value, field_offset)

		//fmt.printfln("field, `%v: %v` at %v (%v B)", field_name, field_type, field_offset, field_size)
		#partial switch field in field_type.variant {
		case runtime.Type_Info_Boolean, runtime.Type_Info_Integer, runtime.Type_Info_Float:
			switch field_size {
			case 1:
				(^u8)(field_ptr)^ = (^u8)(row_data_ptr)^
			case 2:
				(^u16)(field_ptr)^ = u16((^u16le)(row_data_ptr)^)
			case 4:
				(^u32)(field_ptr)^ = u32((^u32le)(row_data_ptr)^)
			case 8:
				(^u64)(field_ptr)^ = u64((^u64le)(row_data_ptr)^)
			case:
				fmt.assertf(false, "Not implemented: %v", field_type)
			}
			row_data_ptr = math.ptr_add(row_data_ptr, field_size)
		case runtime.Type_Info_Array:
			for j in 0 ..< field_size {
				field_ptr[j] = row_data_ptr[field_offset + j]
			}
			row_data_ptr = math.ptr_add(row_data_ptr, field_size)
		case runtime.Type_Info_String:
			string_length := (^int)(row_data_ptr)^
			string_buffer := math.ptr_add(row_data_ptr, 8)[:string_length]
			value_string_buffer := make([]byte, string_length, allocator = allocator)
			for j in 0 ..< string_length {
				value_string_buffer[j] = string_buffer[j]
			}
			value_string_ptr := (^runtime.Raw_String)(field_ptr)
			value_string_ptr.data = raw_data(value_string_buffer)
			value_string_ptr.len = string_length
			row_data_ptr = math.ptr_add(row_data_ptr, 8 + string_length)
		case:
			fmt.assertf(false, "Not implemented, %v: %v", struct_info.names[i], field_type)
		}
	}
	return true
}

hard_delete_table_row :: proc(table: ^Table($T), id: int) {
	// TODO: hard delete row
}
