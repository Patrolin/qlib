package lib_db
import "../path"

DBWrite :: struct {
	file:   path.File,
	offset: int,
	bytes:  []byte,
}
DBTransaction :: struct {
	writes: [dynamic]DBWrite,
}

start_transaction :: proc() {
	return
}
