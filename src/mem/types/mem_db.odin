package lib_mem_types
import "../../fmt"
import "../../math"
import "../../mem"
import "../../os"
import "base:intrinsics"
import "base:runtime"
import "core:strings"
import win "core:sys/windows"

// constants
TABLE_ROW_SIZE :: 256
TABLE_ROW_DATA_SIZE :: TABLE_ROW_SIZE - size_of(DBTableRowHeader)

// TODO: automatic migrations via tags+storing metadata if you want to link tables together
// TODO: BTree(hash(field), id) indexes for fast filter/sort
/* TODO: write ahead log for consistency?
	- have multiple sequentially written files
		- fsync(file); fsync(dir) ahead of time
	- have a checksum for each entry
*/

// types
DBTable :: struct($T: typeid) where intrinsics.type_is_struct(T) {
	file:           os.File,
	data_lock:      mem.Lock,
	data_row_count: int,
}
DBTableHeader :: struct #packed {
	last_used_row_id: u64le,
	next_free_row_id: u64le,
}
#assert(size_of(DBTableHeader) <= TABLE_ROW_SIZE)

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
_read_table_header :: #force_inline proc(file: ^os.File, table_header: ^DBTableHeader) {
	buffer := ([^]byte)(table_header)[:size_of(DBTableHeader)]
	os.read_file_at(file, buffer, 0)
}
@(private)
_write_table_header :: #force_inline proc(file: ^os.File, table_header: ^DBTableHeader) {
	buffer := ([^]byte)(table_header)[:size_of(DBTableHeader)]
	os.write_file_at(file, buffer, 0)
}
@(private)
_read_table_row :: proc(file: ^os.File, row: ^DBTableRow, id: int) {
	buffer := ([^]byte)(row)[:TABLE_ROW_SIZE]
	os.read_file_at(file, buffer, id * TABLE_ROW_SIZE)
}
@(private)
_write_table_row :: proc(file: ^os.File, row: ^DBTableRow, id: int) {
	buffer := ([^]byte)(row)[:TABLE_ROW_SIZE]
	os.write_file_at(file, buffer, id * TABLE_ROW_SIZE)
}
@(private)
_get_free_table_row :: proc(table: ^DBTable($T), table_header: ^DBTableHeader, row: ^DBTableRow) -> (row_id: int) {
	// find free row
	next_unused_row_id := int(table_header.last_used_row_id) + 1
	next_free_row_id := int(table_header.next_free_row_id)
	have_free_row := next_free_row_id > 0
	row_id = have_free_row ? next_free_row_id : next_unused_row_id
	// read table row
	_read_table_row(&table.file, row, row_id)
	// update table_header
	if intrinsics.expect(have_free_row, false) {
		free_row := (^DBTableFreeRowData)(&row.data)
		table_header.next_free_row_id = free_row.next_free_row_id
	} else {
		table_header.last_used_row_id = u64le(next_unused_row_id)
	}
	_write_table_header(&table.file, table_header)
	return
}

// procedures
open_table :: proc($T: typeid, loc := #caller_location) -> ^DBTable(T) {
	// make directories
	named_info := type_info_of(T).variant.(runtime.Type_Info_Named)
	table_name := named_info.name
	os.new_directory("db")
	// make table
	struct_info := named_info.base.variant.(runtime.Type_Info_Struct)
	assert(struct_info.flags >= {.packed}, loc = loc)
	table := new(DBTable(T), allocator = context.allocator)
	// open data file
	file_path := fmt.tprintf("db/%v.bin", table_name)
	file, ok := os.open_file(file_path, {.UniqueAccess, .RandomAccess, .FlushOnWrite})
	assert(ok)
	table.file = file
	// assert only supported field_types
	for i in 0 ..< struct_info.field_count {
		//field_name := struct_info.names[i]
		//field_offset := int(struct_info.offsets[i])
		field_type := struct_info.types[i]

		#partial switch field in field_type.variant {
		case runtime.Type_Info_String:
			fmt.assertf(false, "Not implemented: %v", field, loc = loc)
		case runtime.Type_Info_Slice:
			fmt.assertf(false, "Not implemented: %v", field, loc = loc)
		case runtime.Type_Info_Dynamic_Array:
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
	// compute data_row_count
	table_header: DBTableHeader
	_read_table_header(&table.file, &table_header)
	last_used_row_id := int(table_header.last_used_row_id)
	next_free_row_id := int(table_header.next_free_row_id)

	row: DBTableRow
	free_row_data := (^DBTableFreeRowData)(&row.data)
	free_row_count := 0
	for next_free_row_id > 0 {
		free_row_count += 1
		_read_table_row(&table.file, &row, next_free_row_id)
		next_free_row_id = int(free_row_data.next_free_row_id)
	}
	table.data_row_count = last_used_row_id - free_row_count
	return table
}
// !TODO: get id from struct type and allow setting AND appending, and call this insert instead
append_table_row :: proc(table: ^DBTable($T), value: ^T) {
	mem.get_lock(&table.data_lock)
	defer mem.release_lock(&table.data_lock)
	// get table name
	named_info := type_info_of(T).variant.(runtime.Type_Info_Named)
	table_name := named_info.name
	// get next slot
	table_header: DBTableHeader
	_read_table_header(&table.file, &table_header)
	row: DBTableRow
	row_id := _get_free_table_row(table, &table_header, &row)
	// copy the data
	row.used = true
	row_data_ptr := ([^]byte)(&row.data)
	value_ptr := ([^]byte)(value)
	struct_info := named_info.base.variant.(runtime.Type_Info_Struct)
	for i in 0 ..< struct_info.field_count {
		//field_name := struct_info.names[i]
		field_offset := int(struct_info.offsets[i])
		field_type := struct_info.types[i]
		field_size := size_of(field_type)

		#partial switch field in field_type.variant {
		case runtime.Type_Info_Boolean, runtime.Type_Info_Integer, runtime.Type_Info_Float:
			switch field_size {
			case 1:
				(^u8)(row_data_ptr)^ = (^u8)(value_ptr)^
			case 2:
				(^u16le)(row_data_ptr)^ = u16le((^u16)(value_ptr)^)
			case 4:
				(^u32le)(row_data_ptr)^ = u32le((^u32)(value_ptr)^)
			case 8:
				(^u64le)(row_data_ptr)^ = u64le((^u64)(value_ptr)^)
			case:
				fmt.assertf(false, "Not implemented: %v", field_type)
			}
			row_data_ptr = math.ptr_add(row_data_ptr, field_size)
		case runtime.Type_Info_Array:
			for j in 0 ..< field_size {
				row_data_ptr[field_offset + j] = value_ptr[field_offset + j]
			}
			row_data_ptr = math.ptr_add(row_data_ptr, field_size)
		case:
			fmt.assertf(false, "Not implemented, %v: %v", struct_info.names[i], field_type)
		}
		value_ptr = math.ptr_add(value_ptr, field_size)
	}
	_write_table_row(&table.file, &row, row_id)
	// update `data_row_count` and flush file
	table.data_row_count += 1
}
get_table_row :: proc(table: ^DBTable($T), id: int, value: ^T) -> (ok: bool) {
	named_info := type_info_of(T).variant.(runtime.Type_Info_Named)
	// get the slot
	row: DBTableRow
	_read_table_row(&table.file, &row, id)
	// TODO: row_id_is_invalid || !row.used
	if !row.used {
		value^ = {}
		return false
	}
	// copy the data
	row_data_ptr := ([^]byte)(&row.data)
	value_ptr := ([^]byte)(value)
	struct_info := named_info.base.variant.(runtime.Type_Info_Struct)
	for i in 0 ..< struct_info.field_count {
		//field_name := struct_info.names[i]
		field_offset := int(struct_info.offsets[i])
		field_type := struct_info.types[i]
		field_size := size_of(field_type)

		#partial switch field in field_type.variant {
		case runtime.Type_Info_Boolean, runtime.Type_Info_Integer, runtime.Type_Info_Float:
			switch field_size {
			case 1:
				(^u8)(value_ptr)^ = (^u8)(row_data_ptr)^
			case 2:
				(^u16)(value_ptr)^ = u16((^u16le)(row_data_ptr)^)
			case 4:
				(^u32)(value_ptr)^ = u32((^u32le)(row_data_ptr)^)
			case 8:
				(^u64)(value_ptr)^ = u64((^u64le)(row_data_ptr)^)
			case:
				fmt.assertf(false, "Not implemented: %v", field_type)
			}
			row_data_ptr = math.ptr_add(row_data_ptr, field_size)
		case runtime.Type_Info_Array:
			for j in 0 ..< field_size {
				value_ptr[field_offset + j] = row_data_ptr[field_offset + j]
			}
			row_data_ptr = math.ptr_add(row_data_ptr, field_size)
		case:
			fmt.assertf(false, "Not implemented, %v: %v", struct_info.names[i], field_type)
		}
		value_ptr = math.ptr_add(value_ptr, field_size)
	}
	return true
}
hard_delete_table_row :: proc(table: ^DBTable($T), id: int) {
	// TODO: hard delete row
}
