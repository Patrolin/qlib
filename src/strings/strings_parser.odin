package lib_strings
import "core:strconv"

Parser :: struct {
	slice: string,
}
@(require_results)
parse_prefix :: proc(parser: ^Parser, prefix: string) -> (ok: bool) {
	ok = starts_with(parser.slice, prefix)
	if ok {parser.slice = parser.slice[len(prefix):]}
	return
}
parse_uint :: proc(parser: ^Parser, base := 10) -> (n: uint, ok: bool) {
	assert(base == 10 || base == 16)
	end_index := index_after_multi_ascii(parser.slice, base == 16 ? "0123456789abcdefABCDEF" : "0123456789")
	n, ok = strconv.parse_uint(parser.slice[:end_index], base)
	parser.slice = parser.slice[end_index:]
	return
}
// parse until we see one of the chars in `ascii_chars`
@(require_results)
parse_until_any :: proc(parser: ^Parser, ascii_chars: string) -> (result: string) {
	end_index := index_multi_ascii(parser.slice, ascii_chars)
	result = parser.slice[:end_index]
	parser.slice = parser.slice[end_index:]
	return
}
// parse one after we see one of the chars in `ascii_chars`
@(require_results)
parse_after_any :: proc(parser: ^Parser, ascii_chars: string) -> (result: string) {
	end_index := index_multi_ascii(parser.slice, ascii_chars)
	result = parser.slice[:end_index]
	parser.slice = parser.slice[min(end_index + 1, len(parser.slice)):]
	return
}
