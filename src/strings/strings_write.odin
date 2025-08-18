package lib_strings
import "../bytes"
import "base:intrinsics"

// string writer procs
write_string :: proc(writer: ^bytes.Writer, str: string) {
	assert(writer.procedure != nil)
	escaped_buffer: [2]byte
	escaped_buffer[0] = '\\'
	for i := 0; i < len(str); {
		j := i + index_any_ascii(str[i:], "\\\r\n\"")
		writer.procedure(writer, .Write, transmute([]u8)(str[i:j]))
		escaped_buffer[1] = str[j]
		writer.procedure(writer, .Write, escaped_buffer[:])
		i = j
	}
}
write_int :: proc(writer: ^bytes.Writer, size_of_int: int, value: i64, base: i64 = 10) #no_bounds_check {
	// write negative sign
	value := value
	if intrinsics.expect(value < 0, false) {
		negative_sign := "-"
		writer.procedure(writer, .Write, transmute([]u8)negative_sign)
		value = -value
	}
	write_uint(writer, size_of_int, u64(value), u64(base))
}
write_uint :: proc(writer: ^bytes.Writer, size_of_int: int, value: u64, base: u64 = 10) #no_bounds_check {
	// write backwards into int_buffer
	base_chars := "0123456789abcdef"
	assert(int(base) <= len(base_chars))
	int_buffer: [66]byte
	offset := 65
	for value := value; value > base; value = value / base {
		digit := value % base
		digit_char := base_chars[digit]
		int_buffer[offset] = digit_char
		offset -= 1
	}
	digit := value % base
	digit_char := base_chars[digit]
	int_buffer[offset] = digit_char
	// write base prefix into int_buffer
	if base != 10 {
		offset -= 2
		int_buffer[offset] = '0'
		switch base {
		case 2:
			int_buffer[offset + 1] = 'b'
		case 8:
			int_buffer[offset + 1] = 'o'
		case 16:
			int_buffer[offset + 1] = 'x'
		case:
			assert(false, "Unknown base")
		}
	}
	// write from int_buffer
	writer.procedure(writer, .Write, int_buffer[offset:])
}
