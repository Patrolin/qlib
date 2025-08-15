package lib_strings
import "../bytes"
import "base:intrinsics"

// string writer procs
write_string :: proc(writer: ^bytes.Writer, str: string) {
	assert(writer.procedure != nil)
	escaped_buffer: [2]byte
	escaped_buffer[0] = '\\'
	for i := 0; i < len(str); {
		j := i + index_multi_ascii(str[i:], "\\\r\n\"")
		writer.procedure(writer, .Write, transmute([]u8)(str[i:j]))
		escaped_buffer[1] = str[j]
		writer.procedure(writer, .Write, escaped_buffer[:])
		i = j
	}
}
write_int :: proc(writer: ^bytes.Writer, size_of_int: int, value: i64, base: i64 = 10, base_prefix: string) #no_bounds_check {
	// write negative sign
	value := value
	if intrinsics.expect(value < 0, false) {
		negative_sign := "-"
		writer.procedure(writer, .Write, transmute([]u8)negative_sign)
		value = -value
	}
	write_uint(writer, size_of_int, u64(value), u64(base), base_prefix)
}
write_uint :: proc(writer: ^bytes.Writer, size_of_int: int, value: u64, base: u64 = 10, base_prefix: string) #no_bounds_check {
	// write base prefix
	if base != 10 {
		assert(len(base_prefix) > 0)
		writer.procedure(writer, .Write, transmute([]u8)base_prefix)
	}
	// write backwards into int_buffer
	base_chars := "0123456789abcdef"
	int_buffer: [64]byte
	offset := 63
	for value := value; value > base; value = value / base {
		digit := value % base
		digit_char := base_chars[digit]
		int_buffer[offset] = digit_char
		offset -= 1
	}
	digit := value % base
	digit_char := base_chars[digit]
	int_buffer[offset] = digit_char
	writer.procedure(writer, .Write, int_buffer[offset:])
}
