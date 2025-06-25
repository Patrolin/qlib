package fmt_utils
import "core:bufio"
import "core:fmt"
import "core:io"
import "core:os"

// TODO: replace buffered writer switch indirection with regular function calls
print :: proc(args: ..any, separator := " ", flush := true, newline := true) {
	buf: [1024]byte
	b: bufio.Writer
	bufio.writer_init_with_buf(&b, os.stream_from_handle(os.stdout), buf[:])
	defer bufio.writer_flush(&b)

	// mostly copy paste from fmt.wprint()
	w := bufio.writer_to_writer(&b)
	fi: fmt.Info
	fi.writer = w
	for _, i in args {
		if i > 0 {
			io.write_string(fi.writer, separator, &fi.n)
		}
		fmt.fmt_value(&fi, args[i], 'v')
	}
	if newline {io.write_byte(fi.writer, '\n', &fi.n)}
	if flush {io.flush(w)}
}
printf :: proc(format: string, args: ..any, flush := true, newline := true) {
	buf: [1024]byte
	b: bufio.Writer
	bufio.writer_init_with_buf(&b, os.stream_from_handle(os.stdout), buf[:])
	defer bufio.writer_flush(&b)

	w := bufio.writer_to_writer(&b)
	fmt.wprintf(w, format, ..args, flush = flush, newline = newline)
}
