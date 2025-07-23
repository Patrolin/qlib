package lib_strings
import "base:intrinsics"
import "base:runtime"

ByteEncoder :: struct {
	slice: []byte,
}

@(require_results)
encode_int :: proc(encoder: ^ByteEncoder, value: $T) -> (ok: bool) where intrinsics.type_is_integer(T) #no_bounds_check {
	#assert(T != i16)
	#assert(T != u16)
	#assert(T != i32)
	#assert(T != u32)
	#assert(T != i64)
	#assert(T != u64)
	#assert(T != int)
	#assert(T != uint)

	T_size :: size_of(T)
	if intrinsics.expect(T_size > len(encoder.slice), false) {return false}

	(^T)(&encoder.slice[0])^ = value
	encoder.slice = encoder.slice[T_size:]
	return true
}
@(require_results)
decode_int :: proc(encoder: ^ByteEncoder, $T: typeid) -> (value: T, ok: bool) where intrinsics.type_is_integer(T) #no_bounds_check {
	#assert(T != i16)
	#assert(T != u16)
	#assert(T != i32)
	#assert(T != u32)
	#assert(T != i64)
	#assert(T != u64)
	#assert(T != int)
	#assert(T != uint)

	T_size :: size_of(T)
	if intrinsics.expect(T_size > len(encoder.slice), false) {
		ok = false
		return
	}

	value = (^T)(&encoder.slice[0])^
	encoder.slice = encoder.slice[T_size:]
	ok = true
	return
}

@(require_results)
encode_slice :: proc(encoder: ^ByteEncoder, $T: typeid, value: []byte) -> (ok: bool) where intrinsics.type_is_integer(T) #no_bounds_check {
	#assert(T != i16)
	#assert(T != u16)
	#assert(T != i32)
	#assert(T != u32)
	#assert(T != i64)
	#assert(T != u64)
	#assert(T != int)
	#assert(T != uint)

	T_size :: size_of(T)
	if intrinsics.expect(T_size + len(value) > len(encoder.slice), false) {return false}

	(^T)(&encoder.slice[0])^ = value
	for offset := T_size; offset < T_size + len(value); offset += 1 {
		encoder.slice[offset] = value
	}
	return true
}
@(require_results)
decode_slice :: proc(encoder: ^ByteEncoder, $T: typeid) -> (value: []byte, ok: bool) where intrinsics.type_is_integer(T) #no_bounds_check {
	#assert(T != i16)
	#assert(T != u16)
	#assert(T != i32)
	#assert(T != u32)
	#assert(T != i64)
	#assert(T != u64)
	#assert(T != int)
	#assert(T != uint)

	T_size :: size_of(T)
	if intrinsics.expect(T_size > len(encoder.slice), false) {
		ok = false
		return
	}

	length := int((^T)(&encoder.slice[0])^)
	if intrinsics.expect(T_size + length > len(encoder.slice), false) {
		ok = false
		return
	}

	raw_value := (^runtime.Raw_String)(&value)
	raw_value.data = ([^]byte)(&encoder.slice[T_size])
	raw_value.len = length
	ok = true
	return
}
