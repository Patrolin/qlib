package lib_bytes
import "../mem"

// types
WriterOp :: enum {
	Write,
	Flush,
}
WriterProc :: proc(writer: ^Writer, operator: WriterOp, src_buffer: []byte)
/* NOTE: single threaded */
Writer :: struct {
	procedure:      WriterProc,
	data:           rawptr,
	current_offset: int,
}

// procs
writer_from_buffer :: proc(buffer: ^[]byte) -> Writer {
	return Writer{_buffer_writer_proc, buffer, 0}
}
@(private)
_buffer_writer_proc: WriterProc : proc(writer: ^Writer, operator: WriterOp, src_buffer: []byte) #no_bounds_check {
	dest_buffer := (^[]byte)(writer.data)^
	current_offset := writer.current_offset
	switch operator {
	case .Write:
		// write bytes from src_buffer
		new_offset := current_offset + len(src_buffer)
		assert(new_offset <= len(dest_buffer), "Out of room in dest_buffer.")
		mem.copy_slow(raw_data(src_buffer), len(src_buffer), raw_data(dest_buffer))
		writer.current_offset = new_offset
	case .Flush:
		assert(false, "Unsupported operator: .Flush")
	}
}
