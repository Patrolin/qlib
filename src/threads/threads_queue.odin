package threads_utils
import "../math"
import "../mem"
import "base:intrinsics"
import "core:fmt"

/* TODO: use this for both events and work queue
	- events also need to set `timestamp = time() + MIN_EVENT_DELAY`, so that on the game update thread: `time() >= event.timestamp`
*/
// constants
WaitFreeQueueItemType :: [2]u64

// types
/* TODO: make `WaitFreeQueueData` be a custom size */
WaitFreeQueueData :: [32]WaitFreeQueueItemType // NOTE: size_of(WaitFreeQueueData) needs to be a power of two..
WaitFreeQueue :: struct {
	reader: WaitFreeQueueReader,
	writer: WaitFreeQueueWriter,
	data:   WaitFreeQueueData,
}
WaitFreeQueueReader :: struct #align(mem.CACHE_LINE_SIZE) {
	read_offset: int,
}
#assert(size_of(WaitFreeQueueReader) == mem.CACHE_LINE_SIZE)
WaitFreeQueueWriter :: struct #align(mem.CACHE_LINE_SIZE) {
	writing_offset, written_offset, readable_offset: int,
}
#assert(size_of(WaitFreeQueueWriter) == mem.CACHE_LINE_SIZE)

// procedures
@(require_results, private)
queue_append_or_error_raw :: proc(queue: ^WaitFreeQueue, value_ptr: rawptr) -> (ok: bool) {
	// get the next slot or error
	offset_to_write: int
	for {
		read_offset := intrinsics.atomic_load_explicit(&queue.reader.read_offset, .Seq_Cst)
		offset_to_write = intrinsics.atomic_load_explicit(&queue.writer.writing_offset, .Seq_Cst)
		if offset_to_write - read_offset >= size_of(WaitFreeQueueData) {return}

		next_offset_to_write := offset_to_write + size_of(WaitFreeQueueItemType)
		_, ok = intrinsics.atomic_compare_exchange_weak(&queue.writer.writing_offset, offset_to_write, next_offset_to_write)
		if ok {break}
	}
	// write into it
	next_ptr := math.ptr_add(&queue.data, offset_to_write & (size_of(WaitFreeQueueData) - 1))
	(^WaitFreeQueueItemType)(next_ptr)^ = (^WaitFreeQueueItemType)(value_ptr)^
	// mark it as written
	intrinsics.atomic_add(&queue.writer.written_offset, size_of(WaitFreeQueueItemType))
	// commit all pending writes
	readable_offset := queue.writer.readable_offset
	commit_ok: bool
	for {
		written_offset := intrinsics.atomic_load_explicit(&queue.writer.written_offset, .Seq_Cst)
		writing_offset := intrinsics.atomic_load_explicit(&queue.writer.writing_offset, .Seq_Cst)
		if writing_offset != written_offset {return}
		readable_offset, commit_ok = intrinsics.atomic_compare_exchange_weak(&queue.writer.readable_offset, readable_offset, written_offset)
		if commit_ok {return}
	}
}
@(require_results)
queue_append_or_error :: #force_inline proc(queue: ^WaitFreeQueue, value: ^$T) -> (ok: bool) {
	#assert(size_of(T) <= size_of(WaitFreeQueueItemType))
	return queue_append_or_error_raw(queue, (^WaitFreeQueueItemType)(value))
}
@(require_results, private)
queue_read_or_error_raw :: proc(queue: ^WaitFreeQueue, value: ^WaitFreeQueueItemType) -> (ok: bool) {
	for {
		// read the next value
		offset_to_read := intrinsics.atomic_load_explicit(&queue.reader.read_offset, .Seq_Cst)
		value_ptr := math.ptr_add(&queue.data, offset_to_read & (size_of(WaitFreeQueueData) - 1))
		value^ = (^WaitFreeQueueItemType)(value_ptr)^
		// try to commit the read
		readable_offset := intrinsics.atomic_load_explicit(&queue.writer.readable_offset, .Seq_Cst)
		if offset_to_read >= readable_offset {return}
		next_offset_to_read := offset_to_read + size_of(WaitFreeQueueItemType)
		_, ok = intrinsics.atomic_compare_exchange_weak(&queue.reader.read_offset, offset_to_read, next_offset_to_read)
		if ok {return}
	}
}
@(require_results)
queue_read_or_error :: #force_inline proc(queue: ^WaitFreeQueue, value: ^$T) -> (ok: bool) {
	#assert(size_of(T) <= size_of(WaitFreeQueueItemType))
	return queue_read_or_error_raw(queue, (^WaitFreeQueueItemType)(value))
}
