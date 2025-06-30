package fmt_utils
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
table_append :: proc(tb: ^TableBuilder, args: ..any) {
	row: [dynamic]string
	reserve_dynamic_array(&row, len(args))
	if tb.column_widths == nil {
		tb.column_widths = make([]int, len(args))
	}
	assert(len(args) == len(tb.column_widths))
	for arg, column_index in args {
		sb: strings.Builder
		odin_fmt.sbprint(&sb, arg)
		arg_string := strings.to_string(sb)
		append(&row, arg_string)
		tb.column_widths[column_index] = max(tb.column_widths[column_index], len(arg_string))
	}
	append(&tb.data, row[:])
}
print_table :: proc(tb: ^TableBuilder, format: string) {
	// TODO: print directly instead of allocating
	padded_row := make([]string, len(tb.column_widths))
	padded_row_any := make([]any, len(tb.column_widths))
	for row in tb.data {
		for cell, column_index in row {
			padding_length := max(0, tb.column_widths[column_index] - len(cell))
			padded_cell_string := strings.concatenate({strings.repeat(" ", padding_length), cell})
			padded_row[column_index] = padded_cell_string
			padded_row_any[column_index] = any{&padded_row[column_index], typeid_of(string)}
		}
		printfln(format, ..padded_row_any)
	}
}
printf :: proc(format: string, args: ..any, newline := false) {
	buf: [1024]byte
	b: bufio.Writer
	bufio.writer_init_with_buf(&b, odin_os.stream_from_handle(odin_os.stdout), buf[:])
	w := bufio.writer_to_writer(&b)
	// print
	odin_fmt.wprintf(w, format, ..args, flush = true, newline = newline)
}
printfln :: #force_inline proc(format: string, args: ..any) {
	printf(format, ..args, newline = true)
}
// TODO: replace buffered writer switch indirection with regular function calls
print :: proc(args: ..any, separator := " ", newline := false) {
	buf: [1024]byte
	b: bufio.Writer
	bufio.writer_init_with_buf(&b, odin_os.stream_from_handle(odin_os.stdout), buf[:])
	fi: odin_fmt.Info
	fi.writer = bufio.writer_to_writer(&b)
	// print
	for _, i in args {
		if i > 0 {odin_io.write_string(fi.writer, separator, &fi.n)}
		odin_fmt.fmt_value(&fi, args[i], 'v')
	}
	if newline {odin_io.write_byte(fi.writer, '\n', &fi.n)}
	bufio.writer_flush(&b)
}
println :: #force_inline proc(args: ..any, separator := " ") {
	print(..args, separator = separator, newline = true)
}
