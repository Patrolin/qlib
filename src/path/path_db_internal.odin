package lib_path
import "../fmt"
import "../math"
import "../mem/types"
import "../path"
import "base:intrinsics"
import "base:runtime"

// constants
TABLE_ROW_DATA_SIZE :: TABLE_ROW_SIZE - size_of(DBTableRowHeader)

// types
TableHeaderData :: struct {
	last_used_row_id: u64le,
	next_free_row_id: u64le,
	version:          u64le,
}
TableHeader :: struct {
	using _:    TableHeaderData,
	field_data: [TABLE_ROW_SIZE - size_of(TableHeaderData)]byte `fmt:"-"`,
}
#assert(size_of(TableHeader) == TABLE_ROW_SIZE)
#assert(align_of(TableHeader) == 8)

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
_read_table_header :: #force_inline proc(file: ^File, table_header: ^TableHeader) {
	buffer := ([^]byte)(table_header)[:TABLE_ROW_SIZE]
	read_ok := read_file_at(file, buffer, 0) == TABLE_ROW_SIZE
	if !read_ok {buffer = {}}
}
@(private)
_write_table_header :: #force_inline proc(file: ^File, table_header: ^TableHeader) {
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
_get_new_table_row :: proc(table: ^Table($T), row: ^DBTableRow) -> (row_id: int) {
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

@(private)
_open_table :: proc(table: ^Table(types.void), table_name: string, row_type_named: ^runtime.Type_Info, loc := #caller_location) {
	// open data file
	file_path := fmt.tprintf("db/%v.bin", table_name)
	file, ok := path.open_file(file_path, {.UniqueAccess, .RandomAccess, .NoBuffering, .FlushOnWrite})
	assert(ok, loc = loc)
	table.file = file
	// assert first field is `id: int`
	row_type := row_type_named.variant.(runtime.Type_Info_Named).base.variant.(runtime.Type_Info_Struct)
	assert(row_type.field_count > 0, loc = loc)
	first_field_name := row_type.names[0]
	first_field_type := row_type.types[0]
	_, first_field_type_is_integer := first_field_type.variant.(runtime.Type_Info_Integer)
	first_field_is_id_int := row_type.names[0] == "id" && first_field_type_is_integer && first_field_type.size == 8
	fmt.assertf(first_field_is_id_int, "first_field must be `id: int`, got `%v: %v`", first_field_name, first_field_type)
	// initialize table.header
	_read_table_header(&table.file, &table.header)
	header_data_ptr := math.ptr_add(&table.header.field_data, 0)
	header_data_offset := 0
	for i in 0 ..< row_type.field_count {
		field_name := row_type.names[i]
		field_type := row_type.types[i]
		item_type, item_size, array_type, array_size := _get_field_type_enum(field_type)

		header_data_offset += array_type == .array ? 1 : 0
		header_data_offset += 1 + len(field_name)
		fmt.assertf(len(field_name) <= int(max(u8)), "len(field_name) is too big!")
		fmt.assertf(header_data_offset <= len(table.header.field_data), "Header field_data is too big!")
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

@(private)
_migrate_table :: proc(table: ^Table(types.void), table_name: string, row_type_named: ^runtime.Type_Info, loc := #caller_location) {
	// TODO: _migrate_table
}
