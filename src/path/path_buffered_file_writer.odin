package lib_path
import "../bytes"
import "../math"
import "../mem"
import "../path"
import "base:intrinsics"

/* NOTE: single threaded */
buffered_file_writer :: proc(buffer: []byte, file: ^File) -> bytes.Writer {
	return bytes.Writer{_buffered_file_writer_proc, buffer, 0, file}
}
@(private)
_buffered_file_writer_proc: bytes.WriterProc : proc(writer: ^bytes.Writer, operator: bytes.WriterOp, src_buffer: []byte) #no_bounds_check {
	switch operator {
	case .Write:
		{
			// write all of src_buffer, flushing when needed
			dest_buffer := writer.buffer
			for bytes_to_write := len(src_buffer); bytes_to_write > 0; {
				current_offset := writer.current_offset
				if intrinsics.expect(current_offset == len(writer.buffer), false) {
					path.write_file((^path.File)(writer.extra), writer.buffer)
					current_offset = 0
				}
				bytes_to_copy := min(bytes_to_write, len(dest_buffer) - current_offset)
				mem.copy_slow(math.ptr_add(raw_data(src_buffer), current_offset), bytes_to_copy, raw_data(dest_buffer))
				writer.current_offset = current_offset + bytes_to_copy
				bytes_to_write -= bytes_to_copy
			}
		}
	case .Flush:
		file := (^File)(writer.extra)
		write_file(file, writer.buffer)
		if !(file.flags >= {.FlushOnWrite}) {flush_file(file.handle)}
		writer.current_offset = 0
	case .FlushPartial:
		file := (^File)(writer.extra)
		path.write_file(file, writer.buffer[:writer.current_offset])
		flush_file(file.handle)
		writer.current_offset = 0
	}
}
