package lib_strings
import "../bytes"
import "../fmt"
import "base:intrinsics"

// aliases
buffer_reader :: bytes.buffer_reader

// procs
@(require_results)
read_prefix :: proc(reader: ^bytes.Reader, prefix: string) -> (ok: bool) {
	slice := transmute(string)(reader.buffer[reader.current_offset:])
	ok = starts_with(slice, prefix)
	if ok {reader.current_offset += len(prefix)}
	return
}
@(require_results)
read_until_any_char :: proc(reader: ^bytes.Reader, ascii_chars: string) -> (result: string) {
	slice := transmute(string)(reader.buffer[reader.current_offset:])
	end_index := index_any_ascii(slice, ascii_chars)
	result = slice[:end_index]
	reader.current_offset += end_index
	return
}
@(require_results)
read_after_any_char :: proc(reader: ^bytes.Reader, ascii_chars: string) -> (result: string) {
	slice := transmute(string)(reader.buffer[reader.current_offset:])
	end_index := index_any_ascii(slice, ascii_chars)
	result = slice[:end_index]
	reader.current_offset += end_index
	return
}

@(require_results)
read_int :: proc(reader: ^bytes.Reader, base: i64 = 10) -> (n: i64, ok: bool) {
	is_negative := read_prefix(reader, "-")
	n_u64: u64
	n_u64, ok = read_uint(reader, u64(base))
	n = i64(n_u64)
	if is_negative {n = -n}
	return
}
@(require_results)
read_uint :: proc(reader: ^bytes.Reader, base: u64 = 10) -> (n: u64, ok: bool) {
	slice := transmute(string)(reader.buffer[reader.current_offset:])
	i := 0
	int_digit: u64 = ---
	for ; i < len(slice); i += 1 {
		char := slice[i]
		switch char {
		case '0' ..= '9':
			int_digit = u64(char - '0')
		case 'A' ..= 'F':
			int_digit = u64(char - 'A' + 10)
		case 'a' ..= 'f':
			int_digit = u64(char - 'a' + 10)
		case '_':
			continue
		case:
			break
		}
		new_n := n * base + int_digit
		if intrinsics.expect(int_digit >= base && new_n > n, false) {break}
		n = new_n
	}
	reader.current_offset = i
	ok = i > 0
	return
}
