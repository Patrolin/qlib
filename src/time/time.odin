package time_utils
import "../mem"
import "base:intrinsics"
import "core:fmt"
import core_time "core:time"

// constants
NANOSECOND :: Duration(1)
MICROSECOND :: Duration(1e3)
MILLISECOND :: Duration(1e6)
SECOND :: Duration(1e9)

// types
Duration :: core_time.Duration
CycleCount :: distinct i64

// procedures
as :: #force_inline proc "contextless" (duration: Duration, unit: Duration) -> f64 {
	return f64(duration) / f64(unit)
}
cycles :: #force_inline proc "contextless" () -> CycleCount {
	// NOTE: QueryThreadCycleTime(), GetThreadTimes() and similar are completely broken
	return CycleCount(intrinsics.read_cycle_counter())
}
@(deferred_in_out = _scoped_time_end)
scoped_time :: proc "contextless" (diff_time: ^Duration) -> (start_time: Duration) {
	mem.mfence()
	start_time = time()
	mem.mfence()
	return
}
@(private)
_scoped_time_end :: proc(diff_time: ^Duration, start_time: Duration) {
	mem.mfence()
	diff_time^ = time() - start_time
	mem.mfence()
}
@(deferred_in_out = _scoped_cycles_end)
scoped_cycles :: proc(diff_cycles: ^CycleCount) -> (start_cycles: CycleCount) {
	mem.mfence()
	start_cycles = cycles()
	mem.mfence()
	return
}
@(private)
_scoped_cycles_end :: proc(diff_cycles: ^CycleCount, start_cycles: CycleCount) {
	mem.mfence()
	diff_cycles^ = cycles() - start_cycles
	mem.mfence()
}
