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
TABLE_SLOT_SIZE :: 256
TABLE_SLOT_DATA_SIZE :: TABLE_SLOT_SIZE - size_of(DBTableSlotHeader)

// TODO: automatic migrations via tags+storing metadata if you want to link tables together
// TODO: BTree(hash(field), id) indexes for fast filter/sort
// TODO: replay log for consistency?

// types
DBTable :: struct($T: typeid) where intrinsics.type_is_struct(T) {
	data_view:      os.FileView,
	//strings:   os.FileView,
	data_lock:      mem.Lock,
	data_row_count: int, // NOTE: we compute `data_row_count` at startup, so that it can't desync from `next_unused_slot`
}
DBTableHeader :: struct #packed {
	last_used_slot_id: u64le,
	next_free_slot_id: u64le,
}
#assert(size_of(DBTableHeader) <= TABLE_SLOT_SIZE)

DBTableSlotHeader :: struct #packed {
	used: b8,
}
DBTableSlot :: struct #packed {
	using _: DBTableSlotHeader,
	using _: struct #raw_union {
		next_free_slot_id: u64le,
		data:              void,
	},
}
#assert(size_of(DBTableSlot) <= TABLE_SLOT_SIZE)
#assert(TABLE_SLOT_DATA_SIZE > 0)

// helper procedures
@(private)
_get_table_header :: #force_inline proc(table_data: []byte) -> ^DBTableHeader {
	return (^DBTableHeader)(raw_data(table_data))
}
@(private)
_get_table_slot :: #force_inline proc(table_data: []byte, id: int, $T: typeid) -> ^DBTableSlot {
	if id <= 0 {return nil}
	return (^DBTableSlot)(&table_data[id * TABLE_SLOT_SIZE])
}
@(private)
_get_free_table_slot :: proc(table: ^DBTable($T)) -> ^DBTableSlot {
	table_header := _get_table_header(table.data_view.data)
	// find free slot
	next_unused_slot_id := int(table_header.last_used_slot_id) + 1
	next_free_slot_id := int(table_header.next_free_slot_id)
	have_free_slot := next_free_slot_id > 0
	slot_id := have_free_slot ? next_free_slot_id : next_unused_slot_id
	slot := _get_table_slot(table.data_view.data, slot_id, T)
	// update table_header
	if intrinsics.expect(have_free_slot, false) {
		table_header.next_free_slot_id = slot.next_free_slot_id
	} else {
		table_header.last_used_slot_id = u64le(next_unused_slot_id)
	}
	return slot
}
@(private)
_open_table_file :: proc(file_view: ^os.FileView, file_path_format: string, args: ..any) {
	// open file
	file_path := fmt.tprintf(file_path_format, ..args)
	file, ok := os.open_file(file_path, {.Read, .Write_Preserve, .UniqueAccess, .RandomAccess})
	fmt.assertf(ok, "Failed to open file: %v", file_path)
	file_view.file = file
	// open file_view
	new_file_size := max(1, file_view.file.size)
	new_file_size += math.align_forward(rawptr(uintptr(new_file_size)), mem.PAGE_SIZE)
	ok = os.open_file_view(file_view, new_file_size)
	fmt.assertf(ok, "Failed to open file view: %v", file_path)
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
	_open_table_file(&table.data_view, "db/%v.bin", table_name)
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
	// compute row count
	table_header := _get_table_header(table.data_view.data)
	next_free_slot_id := int(table_header.next_free_slot_id)
	free_slot_count := 0
	for next_free_slot_id > 0 {
		free_slot_count += 1
		slot := _get_table_slot(table.data_view.data, next_free_slot_id, T)
		next_free_slot_id = int(slot.next_free_slot_id)
	}
	table.data_row_count = int(table_header.last_used_slot_id) - free_slot_count
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
	row_slot := _get_free_table_slot(table)
	// copy the data
	row_slot.used = true // NOTE: this only gets stored when we flush the file buffers
	row_ptr := ([^]byte)(&row_slot.data)
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
				(^u8)(row_ptr)^ = (^u8)(value_ptr)^
			case 2:
				(^u16le)(row_ptr)^ = u16le((^u16)(value_ptr)^)
			case 4:
				(^u32le)(row_ptr)^ = u32le((^u32)(value_ptr)^)
			case 8:
				(^u64le)(row_ptr)^ = u64le((^u64)(value_ptr)^)
			case:
				fmt.assertf(false, "Not implemented: %v", field_type)
			}
			row_ptr = math.ptr_add(row_ptr, field_size)
		case runtime.Type_Info_Array:
			for j in 0 ..< field_size {
				row_ptr[field_offset + j] = value_ptr[field_offset + j]
			}
			row_ptr = math.ptr_add(row_ptr, field_size)
		case:
			fmt.assertf(false, "Not implemented, %v: %v", struct_info.names[i], field_type)
		}
		value_ptr = math.ptr_add(value_ptr, field_size)
	}
	// update `data_row_count` and flush file
	table.data_row_count += 1
	win.FlushFileBuffers(table.data_view.file.handle)
}
get_table_row :: proc(table: ^DBTable($T), id: int, value: ^T) -> (ok: bool) {
	named_info := type_info_of(T).variant.(runtime.Type_Info_Named)
	// get the slot
	row_slot := _get_table_slot(table.data_view.data, id, T)
	if row_slot == nil || !row_slot.used {
		value^ = {}
		return false
	}
	// copy the data
	row_ptr := ([^]byte)(&row_slot.data)
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
				(^u8)(value_ptr)^ = (^u8)(row_ptr)^
			case 2:
				(^u16)(value_ptr)^ = u16((^u16le)(row_ptr)^)
			case 4:
				(^u32)(value_ptr)^ = u32((^u32le)(row_ptr)^)
			case 8:
				(^u64)(value_ptr)^ = u64((^u64le)(row_ptr)^)
			case:
				fmt.assertf(false, "Not implemented: %v", field_type)
			}
			row_ptr = math.ptr_add(row_ptr, field_size)
		case runtime.Type_Info_Array:
			for j in 0 ..< field_size {
				value_ptr[field_offset + j] = row_ptr[field_offset + j]
			}
			row_ptr = math.ptr_add(row_ptr, field_size)
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
