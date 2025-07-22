package lib_strings
import "core:strconv"

Parser :: struct {
	str: string,
}
@(require_results)
parse_prefix :: proc(parser: ^Parser, prefix: string) -> (ok: bool) {
	ok = starts_with(parser.str, prefix)
	if ok {parser.str = parser.str[len(prefix):]}
	return
}
parse_uint :: proc(parser: ^Parser, base := 10) -> (n: uint, ok: bool) {
	assert(base == 10 || base == 16)
	end_index := index_after_multi_ascii(parser.str, base == 16 ? "0123456789abcdefABCDEF" : "0123456789")
	n, ok = strconv.parse_uint(parser.str[:end_index], base)
	parser.str = parser.str[end_index:]
	return
}
@(require_results)
parse_until :: proc(parser: ^Parser, ascii_chars: string) -> (result: string) {
	end_index := index_multi_ascii(parser.str, ascii_chars)
	result = parser.str[:end_index]
	parser.str = parser.str[end_index:]
	return
}
@(require_results)
parse_after :: proc(parser: ^Parser, ascii_chars: string) -> (result: string) {
	end_index := index_multi_ascii(parser.str, ascii_chars)
	result = parser.str[:end_index]
	parser.str = parser.str[min(end_index + 1, len(parser.str)):]
	return
}
