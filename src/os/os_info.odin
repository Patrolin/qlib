package os_utils
import "../math"
import "base:runtime"

// globals
info: OsInfo

// types
OsInfo :: struct {
	duration_multiplier: i64,
	page_size:           int,
	large_page_size:     int,
	logical_core_count:  int,
	window_border:       math.AbsoluteRect,
}

// procedures
empty_context :: #force_inline proc "contextless" () -> runtime.Context {
	return runtime.Context{assertion_failure_proc = runtime.default_assertion_failure_proc}
}
