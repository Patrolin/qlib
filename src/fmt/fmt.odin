package fmt_utils
import "base:intrinsics"
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

print_list :: proc(
	arr: $T,
	name := #caller_expression(arr),
) where intrinsics.type_is_array(T) ||
	intrinsics.type_is_dynamic_array(T) ||
	intrinsics.type_is_slice(T) ||
	intrinsics.type_is_map(T) {
	if len(arr) == 0 {
		printfln("%v: []", name)
	} else {
		printfln("%v: [", name)
		for key, value in arr {
			printfln("  %v: %v", key, value)
		}
		println("]")
	}
}
