package lib_strings
import "base:intrinsics"

// NOTE: mostly copy paste from core:strings
@(private)
Ascii_Set :: distinct [8]u32
@(private)
ascii_set_make :: proc(ascii_chars: string) -> (ascii_set: Ascii_Set) #no_bounds_check {
	for i in 0 ..< len(ascii_chars) {
		char := ascii_chars[i]
		assert(char < 0x80)
		ascii_set[char >> 5] |= 1 << uint(char & 31)
	}
	return
}
@(private)
ascii_set_contains :: proc(as: Ascii_Set, c: byte) -> bool #no_bounds_check {
	return as[c >> 5] & (1 << (c & 31)) != 0
}

index_multi_ascii :: proc(str: string, ascii_chars: string) -> int {
	if len(ascii_chars) == 1 {
		return index_byte(str, ascii_chars[0])
	} else {
		as := ascii_set_make(ascii_chars)
		for i in 0 ..< len(str) {
			if ascii_set_contains(as, str[i]) {return i}
		}
		return len(str)
	}
}
index_after_multi_ascii :: proc(str: string, ascii_chars: string) -> int {
	if len(ascii_chars) == 1 {
		return index_after_byte(str, ascii_chars[0])
	} else {
		as := ascii_set_make(ascii_chars)
		for i in 0 ..< len(str) {
			if !ascii_set_contains(as, str[i]) {return i}
		}
		return len(str)
	}
}
