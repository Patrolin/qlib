package lib_bytes

// TODO: Reader
@(require_results)
parse_int :: proc(reader: ^Reader, $T: typeid) -> (value: T, ok: bool) where intrinsics.type_is_integer(T) #no_bounds_check {
	#assert(T != i16)
	#assert(T != u16)
	#assert(T != i32)
	#assert(T != u32)
	#assert(T != i64)
	#assert(T != u64)
	#assert(T != int)
	#assert(T != uint)

	int_buffer: [8]byte
	ok = reader.procedure(reader, .Read, int_buffer)
	if intrinsics.expect(!ok, false) {return}
	value = (^T)(raw_data(int_buffer))^
	reader.current_offset += 8
	return
}
@(require_results)
parse_slice :: proc(reader: ^Reader, $T: typeid) -> (value: []byte, ok: bool) where intrinsics.type_is_integer(T) #no_bounds_check {
	#assert(T != i16)
	#assert(T != u16)
	#assert(T != i32)
	#assert(T != u32)
	#assert(T != i64)
	#assert(T != u64)
	#assert(T != int)
	#assert(T != uint)
	T_size :: size_of(T)

	length: int
	length, ok = parse_int(reader, T)
	if intrinsics.expect(!ok, false) {return}

	raw_value := (^runtime.Raw_String)(&value)
	raw_value.data = ([^]byte)(&encoder.slice[T_size])
	raw_value.len = length
	ok = true
	reader.current_offset += length
	return
}
