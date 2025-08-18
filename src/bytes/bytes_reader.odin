package lib_bytes
import "../math"
import "../mem"

// types
ReaderOp :: enum {
	Read,
}
ReaderProc :: proc(reader: ^Reader, operator: ReaderOp, dest_buffer: []byte) -> (bytes_read: int)
/* NOTE: single threaded */
Reader :: struct {
	procedure:      ReaderProc,
	buffer:         []byte,
	current_offset: int,
}

// procs
buffer_reader :: proc(buffer: []byte) -> Reader {
	return Reader{_buffer_reader_proc, buffer, 0}
}
@(private)
_buffer_reader_proc: ReaderProc : proc(reader: ^Reader, operator: ReaderOp, dest_buffer: []byte) -> (bytes_read: int) #no_bounds_check {
	src_buffer := reader.buffer
	current_offset := reader.current_offset
	switch operator {
	case .Read:
		// read until end of src_buffer
		bytes_read = max(0, min(len(src_buffer) - current_offset, len(dest_buffer)))
		new_offset := current_offset + bytes_read
		mem.copy_slow(math.ptr_add(raw_data(src_buffer), current_offset), len(dest_buffer), raw_data(dest_buffer))
		reader.current_offset = new_offset
	}
	return
}
