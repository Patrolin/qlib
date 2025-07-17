package lib_path
import "../fmt"
import "../math"
import "../mem"
import "../path"
import "base:intrinsics"
import "base:runtime"
import "core:strings"

// constants
TABLE_ROW_SIZE :: 512
TABLE_ROW_DATA_SIZE :: TABLE_ROW_SIZE - size_of(DBTableRowHeader)

// TODO: open_database(database) and use type_polymorphic_record_parameter_value() to get the row types?
// NOTE: a row_id always refers to the same row (until you hard delete that row)

// TODO: automatic migrations when fields change (allow renames via tags?)
// TODO: via tags+storing metadata

/* TODO: write ahead log for consistency?
	- have multiple sequentially written files
		- fsync(file); fsync(dir) ahead of time
	- have a checksum for each entry
*/

// TODO: BTree(hash(field), id) indexes for fast filter/sort

// types
DBTable :: struct($T: typeid) where intrinsics.type_is_struct(T) {
	file:           File,
	data_lock:      mem.Lock,
	data_row_count: int,
	header:         DBTableHeader,
}
DBTableHeader :: struct {
	last_used_row_id: u64le,
	next_free_row_id: u64le,
	data:             [TABLE_ROW_SIZE - 2 * size_of(u64le)]byte `fmt:"-"`,
}
#assert(size_of(DBTableHeader) == TABLE_ROW_SIZE)
#assert(align_of(DBTableHeader) == 8)

DBField_ItemType_MASK :: 0x0f
DBField_ItemType :: enum u8 {
	signed   = 0x00,
	unsigned = 0x01,
	float    = 0x02,
	bool     = 0x03,
	string   = 0x04,
}
DBField_ItemSize_MASK :: 0x30
DBField_ItemSize :: enum u8 {
	u8  = 0x00,
	u16 = 0x10,
	u32 = 0x20,
	u64 = 0x30,
}
DBField_ArrayType_MASK :: 0xc0
DBField_ArrayType :: enum u8 {
	single = 0x00,
	slice  = 0x40,
	array  = 0x80,
}
@(private)
_get_field_type_enum :: proc(
	field_type: ^runtime.Type_Info,
) -> (
	item_type: DBField_ItemType,
	item_size: DBField_ItemSize,
	array_type: DBField_ArrayType,
	array_size: u8,
) {
	item_size_int := field_type.size
	#partial switch field in field_type.variant {
	case runtime.Type_Info_Integer:
		item_type = field.signed ? .signed : .unsigned
	case runtime.Type_Info_Float:
		item_type = .float
	case runtime.Type_Info_Boolean:
		item_type = .bool
	case runtime.Type_Info_String:
		item_type = .string
		item_size_int = 1
	case:
		fmt.assertf(false, "Unsupported field_type: %v", field_type)
	}
	switch item_size_int {
	case 1:
		item_size = .u8
	case 2:
		item_size = .u16
	case 4:
		item_size = .u32
	case 8:
		item_size = .u64
	case:
		fmt.assertf(false, "Unsupported field_type: %v", field_type)
	}
	return
}

DBTableRowHeader :: struct #packed {
	used: b8,
}
DBTableRow :: struct #packed {
	using _: DBTableRowHeader,
	data:    [TABLE_ROW_DATA_SIZE]byte,
}
#assert(size_of(DBTableRow) == TABLE_ROW_SIZE)
#assert(TABLE_ROW_DATA_SIZE > 0)

DBTableFreeRowData :: struct #packed {
	next_free_row_id: u64le,
}
#assert(size_of(DBTableFreeRowData) <= TABLE_ROW_DATA_SIZE)

// helper procedures
@(private)
_read_table_header :: #force_inline proc(file: ^File, table_header: ^DBTableHeader) {
	buffer := ([^]byte)(table_header)[:TABLE_ROW_SIZE]
	read_ok := read_file_at(file, buffer, 0) == TABLE_ROW_SIZE
	if !read_ok {buffer = {}}
}
@(private)
_write_table_header :: #force_inline proc(file: ^File, table_header: ^DBTableHeader) {
	buffer := ([^]byte)(table_header)[:TABLE_ROW_SIZE]
	write_file_at(file, buffer, 0)
}
@(private, require_results)
_read_table_row :: proc(file: ^File, row: ^DBTableRow, id: int) -> (ok: bool) {
	buffer := ([^]byte)(row)[:TABLE_ROW_SIZE]
	return read_file_at(file, buffer, id * TABLE_ROW_SIZE) == TABLE_ROW_SIZE
}
@(private)
_write_table_row :: proc(file: ^File, row: ^DBTableRow, id: int) {
	buffer := ([^]byte)(row)[:TABLE_ROW_SIZE]
	write_file_at(file, buffer, id * TABLE_ROW_SIZE)
}
@(private)
_get_new_table_row :: proc(table: ^DBTable($T), row: ^DBTableRow) -> (row_id: int) {
	// find free row
	next_unused_row_id := int(table.header.last_used_row_id) + 1
	next_free_row_id := int(table.header.next_free_row_id)
	have_free_row := next_free_row_id > 0
	row_id = have_free_row ? next_free_row_id : next_unused_row_id
	// update table_header
	if intrinsics.expect(have_free_row, false) {
		_ = _read_table_row(&table.file, row, row_id)
		free_row := (^DBTableFreeRowData)(&row.data)
		table.header.next_free_row_id = free_row.next_free_row_id
	} else {
		table.header.last_used_row_id = u64le(next_unused_row_id)
	}
	_write_table_header(&table.file, &table.header)
	return
}

// procedures
// TODO: we can't just do open_database(db: ^DBStruct), because we have no way to get the table row types
open_table :: proc(table: ^$T/DBTable($V), table_name: string, loc := #caller_location) where intrinsics.type_is_struct(T) {
	// make directory
	path.new_directory("db")
	// open data file
	file_path := fmt.tprintf("db/%v.bin", table_name)
	file, ok := path.open_file(file_path, {.UniqueAccess, .RandomAccess, .NoBuffering, .FlushOnWrite})
	assert(ok, loc = loc)
	table.file = file
	// assert first field is `id: int`
	row_type := type_info_of(V).variant.(runtime.Type_Info_Named).base.variant.(runtime.Type_Info_Struct)
	assert(row_type.field_count > 0, loc = loc)
	first_field_name := row_type.names[0]
	first_field_type := row_type.types[0]
	_, first_field_type_is_integer := first_field_type.variant.(runtime.Type_Info_Integer)
	first_field_is_id_int := row_type.names[0] == "id" && first_field_type_is_integer && first_field_type.size == 8
	fmt.assertf(first_field_is_id_int, "first_field must be `id: int`, got `%v: %v`", first_field_name, first_field_type)
	// assert only supported field_types
	for i in 0 ..< row_type.field_count {
		field_type := row_type.types[i]

		#partial switch field in field_type.variant {
		case runtime.Type_Info_Dynamic_Array:
			fmt.assertf(false, "Not implemented: %v", field, loc = loc)
		case runtime.Type_Info_Slice:
			fmt.assertf(false, "Not implemented: %v", field, loc = loc)
		case runtime.Type_Info_Any,
		     runtime.Type_Info_Pointer,
		     runtime.Type_Info_Multi_Pointer,
		     runtime.Type_Info_Soa_Pointer,
		     runtime.Type_Info_Procedure,
		     runtime.Type_Info_Type_Id:
			fmt.assertf(false, "Cannot store pointer field_type in database: %v", field, loc = loc)
		}
	}
	// initialize the table.header
	_read_table_header(&table.file, &table.header)
	header_data_ptr := math.ptr_add(&table.header.data, 0)
	header_data_offset := 0
	for i in 0 ..< row_type.field_count {
		field_name := row_type.names[i]
		field_type := row_type.types[i]
		item_type, item_size, array_type, array_size := _get_field_type_enum(field_type)

		header_data_offset += array_type == .array ? 1 : 0
		header_data_offset += 1 + len(field_name)
		fmt.assertf(len(field_name) <= int(max(u8)), "len(field_name) is too big!")
		fmt.assertf(header_data_offset <= len(table.header.data), "Header data is too big!")
		// store the DBField type
		(^u8)(header_data_ptr)^ = u8(item_type) | u8(item_size) | u8(array_type)
		header_data_ptr = math.ptr_add(header_data_ptr, 1)
		// store the array size
		if array_type == .array {
			(^u8)(header_data_ptr)^ = u8(array_size)
			header_data_ptr = math.ptr_add(header_data_ptr, 1)
		}
		// store the len(field_name)
		(^u8)(header_data_ptr)^ = u8(len(field_name))
		header_data_ptr = math.ptr_add(header_data_ptr, 1)
		// store the field_name
		for i in 0 ..< len(field_name) {
			header_data_ptr[i] = field_name[i]
		}
	}
	_write_table_header(&table.file, &table.header)
	// compute data_row_count
	last_used_row_id := int(table.header.last_used_row_id)
	next_free_row_id := int(table.header.next_free_row_id)

	row: DBTableRow
	free_row_data := (^DBTableFreeRowData)(&row.data)
	free_row_count := 0
	for next_free_row_id > 0 {
		free_row_count += 1
		_ = _read_table_row(&table.file, &row, next_free_row_id)
		next_free_row_id = int(free_row_data.next_free_row_id)
	}
	table.data_row_count = last_used_row_id - free_row_count
}

insert_table_row :: proc(table: ^DBTable($T), value: ^T) -> (ok: bool) {
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

get_table_row :: proc(table: ^DBTable($T), id: int, value: ^T, allocator := context.temp_allocator) -> (ok: bool) {
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

hard_delete_table_row :: proc(table: ^DBTable($T), id: int) {
	// TODO: hard delete row
}
