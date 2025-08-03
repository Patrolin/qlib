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

FieldInfo :: distinct u8
FieldInfo_ItemType :: enum FieldInfo {
	invalid  = 0x00,
	signed   = 0x01,
	unsigned = 0x02,
	float    = 0x03,
	bool     = 0x04,
	string   = 0x05,
}
FieldInfo_ItemSize :: enum FieldInfo {
	u8  = 0x00,
	u16 = 0x10,
	u32 = 0x20,
	u64 = 0x30,
}
FieldInfo_ArrayType :: enum FieldInfo {
	single = 0x00,
	slice  = 0x40,
	array  = 0x80,
}
FieldArraySize :: u8
field_item_type :: #force_inline proc(field_info: FieldInfo) -> FieldInfo_ItemType {
	return FieldInfo_ItemType(field_info & 0x0f)
}
field_item_size :: #force_inline proc(field_info: FieldInfo) -> FieldInfo_ItemSize {
	return FieldInfo_ItemSize(field_info & 0x30)
}
field_array_type :: #force_inline proc(field_info: FieldInfo) -> FieldInfo_ArrayType {
	return FieldInfo_ArrayType(field_info & 0xc0)
}

@(private)
_get_field_info :: proc(field_type: ^runtime.Type_Info) -> (field_info: FieldInfo, array_size: FieldArraySize) {
	item_type: FieldInfo_ItemType
	item_size: FieldInfo_ItemSize
	array_type: FieldInfo_ArrayType
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
	field_info = FieldInfo(item_type) | FieldInfo(item_size) | FieldInfo(array_type)
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
@(private)
_tprint_field_info :: proc(field_info: FieldInfo, array_size: FieldArraySize) -> string {
	item_type := field_item_type(field_info)
	item_size := field_item_size(field_info)
	array_type := field_array_type(field_info)
	item_size_string := ""
	switch item_size {
	case .u8:
		item_size_string = "8"
	case .u16:
		item_size_string = "16"
	case .u32:
		item_size_string = "32"
	case .u64:
		item_size_string = "64"
	}

	switch item_type {
	case .invalid:
		return "invalid"
	case .signed:
		return fmt.tprint("s", item_size_string, separator = "")
	case .unsigned:
		return fmt.tprint("u", item_size_string, separator = "")
	case .float:
		return fmt.tprint("f", item_size_string, separator = "")
	case .bool:
		return fmt.tprint("b", item_size_string, separator = "")
	case .string:
		return "string"
	}
	return "invalid"
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
	new_version:        int,
	// .New if current_index == -1 else .Move
	current_index:      int,
	current_field_info: FieldInfo,
	current_array_size: FieldArraySize,
	new_field_info:     FieldInfo,
	new_array_size:     FieldArraySize,
}
@(private)
_migrate_table :: proc(table: ^Table(types.void), table_name: string, row_type_named: ^runtime.Type_Info, loc := #caller_location) {
	// read table.header.field_types
	acc_fields: map[string]FieldMigration
	table_user_version := int(table.header.user_version)
	field_index := 0
	if table_user_version != 0 {
		encoder := strings.ByteEncoder{table.header.field_types[:]}
		for {
			field_info_raw, field_info_ok := strings.decode_int(&encoder, u8)
			field_info := FieldInfo(field_info_raw)
			item_type := field_item_type(field_info)
			array_type := field_array_type(field_info)
			if !field_info_ok || item_type == .invalid {break}
			assert(array_type != .array)

			field_name_raw, field_name_ok := strings.decode_slice(&encoder, u64le)
			field_name := transmute(string)(field_name_raw)
			fmt.assertf(field_name_ok, "Error reading header.field_types")

			acc_fields[field_name] = FieldMigration{table_user_version, field_index, field_info, 0, field_info, 0}
			field_index += 1
		}
	}
	fmt.print_list(acc_fields)
	// assert that first field in `row_type` is `id: int`
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
		for len(field_tag.slice) > 0 {
			migration, ok := _read_migration_tag(&field_tag)
			new_user_version = max(new_user_version, migration.version)
		}
	}
	// compute new migrations
	for version_to_apply in table_user_version + 1 ..= new_user_version {
		for i in 0 ..< row_type.field_count {
			field_name := row_type.names[i]
			field_type := row_type.types[i]
			field_info, array_size := _get_field_info(field_type)
			assert(array_size == 0)
			field_tag := strings.Parser{row_type.tags[i]}
			for len(field_tag.slice) > 0 {
				migration_tag, ok := _read_migration_tag(&field_tag)
				if ok && migration_tag.version == version_to_apply {
					operators_string := strings.Parser{migration_tag.operators_string}
					for len(operators_string.slice) > 0 {
						migration_operator, ok := _read_migration_operator(&operators_string)
						if !ok {break}
						switch m in migration_operator {
						case MigrationNew:
							current_field, already_exists := acc_fields[field_name]
							fmt.assertf(
								!already_exists,
								"Cannot create new field `%v: %v`, field already exists: `%v: %v`",
								field_name,
								field_type,
								current_field,
								_tprint_field_info(current_field.current_field_info, current_field.current_array_size),
							)
							acc_fields[field_name] = FieldMigration{migration_tag.version, -1, 0, 0, field_info, 0}
						case MigrationDrop:
							delete_key(&acc_fields, m.name) // NOTE: don't error if it doesn't exist
						case MigrationMove:
							from_key, from_field := delete_key(&acc_fields, m.from)
							if from_key != "" { 	// NOTE: don't error if it doesn't exist
								from_field.new_field_info, from_field.new_array_size = _get_field_info(field_type)
								from_field.new_version = migration_tag.version
								acc_fields[field_name] = from_field
							}
						}
					}
				}
			}
		}
	}
	fmt.print_list(acc_fields)
	// assert that old fields are all specified
	for field_name, field in acc_fields {
		fmt.assertf(
			field.new_version == new_user_version,
			"Missing migration for old field `%v: %v` in type `%v`",
			field_name,
			_tprint_field_info(field.current_field_info, field.current_array_size),
			row_type_named,
		)
	}
	// assert that new fields are specified correctly
	for i in 0 ..< row_type.field_count {
		field_name := row_type.names[i]
		field_type := row_type.types[i]
		migration, ok := &acc_fields[field_name]
		fmt.assertf(ok, "Missing migration for new field `%v: %v` in type `%v`", field_name, field_type, row_type_named)
		real_field_info, real_array_size := _get_field_info(field_type)
		fmt.assertf(
			migration.new_field_info == real_field_info && migration.new_array_size == real_array_size,
			"Type mismatch in migration for `%v: %v` in type %v, migration: `%v: %v`",
			field_name,
			field_type,
			row_type_named,
			field_name,
			_tprint_field_info(migration.new_field_info, migration.current_array_size),
		)
	}
	// TODO: create or migrate the table
	assert(false, "TODO: migrate the table if necessary")
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
		migration.operators_string = strings.parse_after_any(field_tag, " ")
		ok = true
		return
	}
	migration.operators_string = strings.parse_after_any(field_tag, " ")
	return
}

@(private)
FieldMigrationOperator :: union {
	MigrationNew,
	MigrationDrop,
	MigrationMove,
}
MigrationNew :: struct {}
MigrationDrop :: struct {
	name: string,
}
MigrationMove :: struct {
	from: string,
}
@(private)
_read_migration_operator :: proc(parser: ^strings.Parser) -> (migration_operator: FieldMigrationOperator, ok: bool) {
	value_for_error := parser.slice
	if intrinsics.expect(strings.parse_prefix(parser, "+"), true) {
		migration_operator = MigrationNew{}
		ok = true
	} else if intrinsics.expect(strings.parse_prefix(parser, "-"), true) {
		name := strings.parse_until_any(parser, " ")
		fmt.assertf(len(name) > 0, "Invalid migration string: '%v'", value_for_error)
		migration_operator = MigrationDrop{name}
		ok = true
	} else if intrinsics.expect(strings.parse_prefix(parser, "/"), true) {
		from := strings.parse_until_any(parser, " ")
		fmt.assertf(len(from) > 0, "Invalid migration string: '%v'", value_for_error)
		migration_operator = MigrationMove{from}
		ok = true
	}
	return
}
