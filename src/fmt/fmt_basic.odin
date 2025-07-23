package fmt_utils
import "base:intrinsics"
import "core:bufio"
import odin_fmt "core:fmt"
import odin_io "core:io"
import odin_os "core:os"
import "core:strings"

wprint :: proc(w: odin_io.Writer, args: ..any, separator := " ", newline := false) {
	#force_inline odin_fmt.wprint(w, ..args, sep = separator, flush = false)
	if newline {odin_io.write_byte(w, '\n', nil)}
	odin_io.flush(w)
}
wprintf :: proc(w: odin_io.Writer, format: string, args: ..any, newline := false) {
	#force_inline odin_fmt.wprintf(w, format, ..args, flush = false)
	if newline {odin_io.write_byte(w, '\n', nil)}
	odin_io.flush(w)
}

tprint :: proc(args: ..any, separator := " ", newline := false) -> string {
	sb := strings.builder_make_none(allocator = context.temp_allocator)
	wprint(strings.to_writer(&sb), ..args, separator = separator, newline = newline)
	return strings.to_string(sb)
}
tprintf :: proc(format: string, args: ..any, newline := false) -> string {
	sb := strings.builder_make_none(allocator = context.temp_allocator)
	wprintf(strings.to_writer(&sb), format, ..args, newline = newline)
	return strings.to_string(sb)
}

sbprint :: proc(sb: ^strings.Builder, args: ..any, separator := " ", newline := false) {
	wprint(strings.to_writer(sb), ..args, separator = separator, newline = newline)
}
sbprintf :: proc(sb: ^strings.Builder, format: string, args: ..any, newline := false) {
	wprintf(strings.to_writer(sb), format, ..args, newline = newline)
}

// TODO: replace buffered-writer-switch-indirection with regular function calls
print :: proc(args: ..any, separator := " ", newline := false) {
	buf: [1024]byte
	buffered_w: bufio.Writer
	bufio.writer_init_with_buf(&buffered_w, odin_os.stream_from_handle(odin_os.stdout), buf[:])
	wprint(bufio.writer_to_writer(&buffered_w), ..args, separator = separator, newline = newline)
}
printf :: proc(format: string, args: ..any, newline := false) {
	buf: [1024]byte
	buffered_w: bufio.Writer
	bufio.writer_init_with_buf(&buffered_w, odin_os.stream_from_handle(odin_os.stdout), buf[:])
	wprintf(bufio.writer_to_writer(&buffered_w), format, ..args, newline = newline)
}

println :: #force_inline proc(args: ..any, separator := " ") {
	print(..args, separator = separator, newline = true)
}
printfln :: #force_inline proc(format: string, args: ..any) {
	printf(format, ..args, newline = true)
}

@(disabled = ODIN_DISABLE_ASSERT)
assertf :: #force_inline proc(condition: bool, format: string, args: ..any, loc := #caller_location) {
	if intrinsics.expect(!condition, false) {
		message := tprintf(format, ..args)
		assertion_failure_proc := context.assertion_failure_proc
		assertion_failure_proc("runtime assertion", message, loc)
	}
}
