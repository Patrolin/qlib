package lib_strings
import "../bytes"

@(require_results)
read_prefix :: proc(reader: ^bytes.Reader, prefix: string) -> (ok: bool) {
	slice := (^string)(reader.data)^[reader.current_offset:]
	ok = starts_with(slice, prefix)
	if ok {reader.current_offset += len(prefix)}
	return
}
read_int :: proc(reader: ^bytes.Reader, base := 10) -> (n: uint, ok: bool) {
	assert(false, "Not implemented")
	return
}
read_uint :: proc(reader: ^bytes.Reader, base := 10) -> (n: uint, ok: bool) {
	assert(false, "Not implemented")
	return
}
@(require_results)
read_until_any_char :: proc(reader: ^bytes.Reader, ascii_chars: string) -> (result: string) {
	slice := (^string)(reader.data)^[reader.current_offset:]
	end_index := index_multi_ascii(slice, ascii_chars)
	result = slice[:end_index]
	reader.current_offset += end_index
	return
}
@(require_results)
read_after_any_char :: proc(reader: ^bytes.Reader, ascii_chars: string) -> (result: string) {
	slice := (^string)(reader.data)^[reader.current_offset:]
	end_index := index_multi_ascii(slice, ascii_chars)
	result = slice[:end_index]
	reader.current_offset += end_index
	return
}
