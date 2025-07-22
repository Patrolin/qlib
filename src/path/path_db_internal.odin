package lib_path
import "../fmt"
import "../math"
import "../mem/types"
import "../path"
import "../strings"
import "base:intrinsics"
import "base:runtime"
import "core:strconv"

// constants
TABLE_ROW_DATA_SIZE :: TABLE_ROW_SIZE - size_of(DBTableRowHeader)

// types
TableHeaderData :: struct {
	last_used_row_id: u64le,
	next_free_row_id: u64le,
	user_version:     u64le,
}
TableHeader :: struct {
	using _:     TableHeaderData,
	field_types: [TABLE_ROW_SIZE - size_of(TableHeaderData)]byte `fmt:"-"`,
}
#assert(size_of(TableHeader) == TABLE_ROW_SIZE)
#assert(align_of(TableHeader) == 8)

FieldType :: distinct u8
Field_ItemType :: enum FieldType {
	invalid  = 0x00,
	signed   = 0x01,
	unsigned = 0x02,
	float    = 0x03,
	bool     = 0x04,
	string   = 0x05,
}
Field_ItemSize :: enum FieldType {
	u8  = 0x00,
	u16 = 0x10,
	u32 = 0x20,
	u64 = 0x30,
}
Field_ArrayType :: enum FieldType {
	single = 0x00,
	slice  = 0x40,
	array  = 0x80,
}
field_item_type :: #force_inline proc(field_type: FieldType) -> Field_ItemType {
	return Field_ItemType(field_type & 0x0f)
}
field_item_size :: #force_inline proc(field_type: FieldType) -> Field_ItemSize {
	return Field_ItemSize(field_type & 0x30)
}
field_array_type :: #force_inline proc(field_type: FieldType) -> Field_ArrayType {
	return Field_ArrayType(field_type & 0xc0)
}

@(private)
_get_field_type_enum :: proc(
	field_type: ^runtime.Type_Info,
) -> (
	item_type: Field_ItemType,
	item_size: Field_ItemSize,
	array_type: Field_ArrayType,
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
		item_size_int = 1
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
	_read_table_header(&table.file, &table.header)
	// migrate
	_migrate_table(table, table_name, row_type_named)
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
FieldMigration :: struct {
	version: int,
	name:    string,
	type:    FieldType,
	index:   int,
}
@(private)
_migrate_table :: proc(table: ^Table(types.void), table_name: string, row_type_named: ^runtime.Type_Info, loc := #caller_location) {
	// read current_fields
	current_fields: map[string]FieldMigration
	table_user_version := int(table.header.user_version)
	field_index := 0
	if table_user_version != 0 {
		field_types_offset := 0
		for field_types_offset < len(table.header.field_types) {
			field_type := FieldType(table.header.field_types[field_types_offset])
			item_type := field_item_type(field_type)
			if item_type == .invalid {break}

			field_name: string
			ok := _read_var_string(&field_name, table.header.field_types[field_types_offset + 1:])
			fmt.assertf(ok, "Error reading header.field_types")

			current_fields[field_name] = FieldMigration{table_user_version, field_name, field_type, field_index}
			field_index += 1
		}
	}
	fmt.printfln("current_fields: %v", current_fields)
	// assert first field is `id: int`
	row_type := row_type_named.variant.(runtime.Type_Info_Named).base.variant.(runtime.Type_Info_Struct)
	assert(row_type.field_count > 0, loc = loc)
	first_field_name := row_type.names[0]
	first_field_type := row_type.types[0]
	_, first_field_type_is_integer := first_field_type.variant.(runtime.Type_Info_Integer)
	first_field_is_id_int := row_type.names[0] == "id" && first_field_type_is_integer && first_field_type.size == 8
	fmt.assertf(first_field_is_id_int, "first_field must be `id: int`, got `%v: %v`", first_field_name, first_field_type)
	// get new_user_version
	new_user_version := 1
	for i in 0 ..< row_type.field_count {
		field_name := row_type.names[i]
		field_tag := strings.Parser{row_type.tags[i]}
		for len(field_tag.str) > 0 {
			migration, ok := _read_migration_tag(&field_tag)
			new_user_version = max(new_user_version, migration.version)
			fmt.printfln("migration: %v, ok: %v", migration, ok)
		}
	}
	fmt.printfln("new_user_version: %v", new_user_version)
	// compute new migrations
	need_to_migrate := false
	for version_to_apply in table_user_version + 1 ..= new_user_version {
		for i in 0 ..< row_type.field_count {
			field_name := row_type.names[i]
			field_type := row_type.types[i]
			field_tag := strings.Parser{row_type.tags[i]}
			for len(field_tag.str) > 0 {
				migration_tag, ok := _read_migration_tag(&field_tag)
				if ok && migration_tag.version == version_to_apply {
					operators_string := strings.Parser{migration_tag.operators_string}
					for len(operators_string.str) > 0 {
						migration_operator, ok := _read_migration_operator(&operators_string)
						if ok {
							fmt.printfln("%v: %v", field_name, migration_operator)
							switch migration_operator.type {
							case .New:
								current_field, already_exists := current_fields[field_name]
								fmt.assertf(
									!already_exists,
									"Cannot create new field (%v: %v), field already exists: %v",
									field_name,
									field_type,
									current_field,
								)
								current_fields[field_name] = FieldMigration{migration_tag.version, field_name, _get_field_type_enum(field_type), -1}
								need_to_migrate = true
							case .Move, .Drop:
								assert(false, "TODO")
							}
						}
					}
				}
			}
		}
	}
	fmt.printfln("fields_to_migrate_to: %v", current_fields)
	// parse new fields
	for i in 0 ..< row_type.field_count {
		field_name := row_type.names[i]
		field_type := row_type.types[i]
		field_tag := row_type.tags[i]
		field_offset := int(row_type.offsets[i])
		item_type, item_size, array_type, array_size := _get_field_type_enum(field_type)
		field_type_enum := FieldType(item_type) | FieldType(item_size) | FieldType(array_type)
		assert(array_size == 0)

		current_field, already_exists := &current_fields[field_name]
		fmt.assertf(already_exists, "Missing migration for %v: %v", field_name, field_type)
		fmt.printfln("%v: %v, current_field: %v", field_name, field_type, current_fields[field_name])
	}
	// TODO: migrate the table if necessary
	assert(false)
}
@(private)
FieldMigrationTag :: struct {
	version:          int,
	operators_string: string,
}
@(private)
_read_migration_tag :: proc(field_tag: ^strings.Parser) -> (migration: FieldMigrationTag, ok: bool) {
	for {
		strings.parse_prefix(field_tag, "v") or_break
		migration.version = int(strings.parse_uint(field_tag, 10) or_break)
		strings.parse_prefix(field_tag, ":") or_break
		migration.operators_string = strings.parse_after(field_tag, " ")
		ok = true
		return
	}
	migration.operators_string = strings.parse_after(field_tag, " ")
	return
}
@(private)
FieldMigrationOperatorType :: enum {
	New,
	Move,
	Drop,
}
@(private)
FieldMigrationOperator :: struct {
	type: FieldMigrationOperatorType,
}
@(private)
_read_migration_operator :: proc(operators_string: ^strings.Parser) -> (migration_operator: FieldMigrationOperator, ok: bool) {
	operator := strings.parse_until(operators_string, ",")
	if operator == "new" {
		migration_operator.type = .New
		ok = true
	} else {
		assert(false, "TODO")
	}
	return
}

@(private, require_results)
_read_var_string :: proc(value_ptr: ^string, buffer: []byte, allocator := context.temp_allocator) -> (ok: bool) {
	assert(len(buffer) >= 8)
	string_length := (^int)(raw_data(buffer))^
	if 8 + string_length > len(buffer) {return false}
	string_buffer := buffer[8:8 + string_length]
	value_buffer := make([]byte, string_length, allocator = allocator)
	for j in 0 ..< string_length {
		value_buffer[j] = string_buffer[j]
	}
	raw_value_ptr := (^runtime.Raw_String)(value_ptr)
	raw_value_ptr.data = raw_data(value_buffer)
	raw_value_ptr.len = string_length
	return true
}
