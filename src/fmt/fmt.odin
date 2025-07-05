package fmt_utils
import "base:intrinsics"
import "core:bufio"
import odin_fmt "core:fmt"
import odin_io "core:io"
import odin_os "core:os"
import "core:strings"

// types
TableBuilder :: struct {
	data:          [dynamic][]string,
	column_widths: []int,
}

// procedures
table_append :: proc(tb: ^TableBuilder, args: ..string) {
	// create column_widths
	if tb.column_widths == nil {
		tb.column_widths = make([]int, len(args))
	}
	// assert on len(column_widths)
	assert(len(args) == len(tb.column_widths))
	for cell, column_index in args {
		rune_count := 0
		for _ in cell {rune_count += 1}
		tb.column_widths[column_index] = max(tb.column_widths[column_index], rune_count)
	}
	// copy row
	row := make([]string, len(args))
	for arg, i in args {row[i] = arg}
	append(&tb.data, row)
}
table_append_break :: proc(tb: ^TableBuilder) {
	append(&tb.data, nil)
}
print_table :: proc(tb: ^TableBuilder, format: string) {
	// TODO: print directly instead of allocating
	padded_row := make([]string, len(tb.column_widths))
	padded_row_any := make([]any, len(tb.column_widths))
	for row in tb.data {
		if row == nil {
			println()
			continue
		}
		for cell, column_index in row {
			rune_count := 0
			for _ in cell {rune_count += 1}
			padding_length := max(0, tb.column_widths[column_index] - rune_count)
			padded_cell_string := strings.concatenate({strings.repeat(" ", padding_length), cell})
			padded_row[column_index] = padded_cell_string
			padded_row_any[column_index] = any{&padded_row[column_index], typeid_of(string)}
		}
		printfln(format, ..padded_row_any)
	}
}

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

// TODO: replace buffered writer switch indirection with regular function calls
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
