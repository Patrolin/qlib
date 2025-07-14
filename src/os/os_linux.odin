package os_utils
import "base:runtime"
import "core:strings"
import "core:sys/linux"

// common procedures
init :: #force_inline proc "contextless" () -> runtime.Context {
	ctx := empty_context()
	return ctx
}

// types
linux_Stat :: linux.Stat

// helper functions
linux_S_IFDIR :: 0x4000

// string procedures
linux_string_to_cstring :: proc(str: string, allocator := context.temp_allocator) -> cstring {
	return strings.clone_to_cstring(str, allocator = allocator)
}
linux_cstring_to_string :: #force_inline proc(cstr: cstring) -> string {
	return string(cstr)
}
