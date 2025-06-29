package os_utils
import "../math"

// globals
info: OsInfo

// types
OsInfo :: struct {
	_time_multiplier:   i64,
	page_size:          int,
	large_page_size:    int,
	logical_core_count: int,
	window_border:      math.AbsoluteRect,
}
