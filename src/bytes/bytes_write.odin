package lib_bytes
import "base:intrinsics"
import "base:runtime"

@(require_results)
write_int :: proc(writer: ^Writer, value: $T) -> (ok: bool) where intrinsics.type_is_integer(T) #no_bounds_check {
	#assert(T != i16)
	#assert(T != u16)
	#assert(T != i32)
	#assert(T != u32)
	#assert(T != i64)
	#assert(T != u64)
	#assert(T != int)
	#assert(T != uint)

	int_buffer := [8]byte
	(^T)(raw_data(int_buffer))^ = value
	writer.procedure(writer, .Write, int_buffer[:size_of(T)])
	return true
}

@(require_results)
write_slice :: proc(writer: ^Writer, $T: typeid, slice: []byte) -> (ok: bool) where intrinsics.type_is_integer(T) #no_bounds_check {
	#assert(T != i16)
	#assert(T != u16)
	#assert(T != i32)
	#assert(T != u32)
	#assert(T != i64)
	#assert(T != u64)
	#assert(T != int)
	#assert(T != uint)

	int_buffer := [8]byte
	(^T)(raw_data(int_buffer))^ = len(slice)
	writer.procedure(writer, .Write, int_buffer[:size_of(T)])
	writer.procedure(writer, .Write, slice)
	return true
}
