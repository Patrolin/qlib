package lib_db
import "../bytes"
import "../fmt"
import "../path"
import "../timing"
import "base:intrinsics"

// constants
MAX_WAL_COUNT :: 3

// types
DBWrite :: struct {
	file:   path.File,
	offset: int,
	bytes:  []byte,
}
DBTransaction :: [dynamic]DBWrite
WriteAheadLog :: struct {
	time:      timing.Time,
	index:     int,
	file_name: string,
	file:      path.File,
}

// globals
_opened_wal := WriteAheadLog{{}, -1, {}}

// procs
commit_transaction :: proc(transaction: DBTransaction) {
	if _opened_wal.index == -1 || timing.get_time()._nsec > timing.add(_opened_wal.time, timing.SECOND)._nsec {
		if intrinsics.expect(_opened_wal.index != -1, true) {
			path.close_file(_opened_wal.file.handle)
		}
		new_index := (_opened_wal.index + 1) % MAX_WAL_COUNT
		new_path := fmt.tprintf("db/tmp/%v.bin", new_index)
		ok: bool
		_opened_wal.file, ok = path.open_file(new_path, {.NoBuffering, .FlushOnWrite, .UniqueAccess})
	}
	buffer: [ROW_SIZE]byte
	writer := path.file_writer(_opened_wal.file, buffer)
	for write in transaction {
		assert(bytes.blip_slice(writer, u64le, write.file_name))
		assert(bytes.blip_slice(writer, u64le, write.bytes))
	}
}
