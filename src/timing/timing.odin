package duration_utils
import "../fmt"
import "base:intrinsics"
import odin_time "core:time"

// constants
NANOSECOND :: Duration(1)
MICROSECOND :: Duration(1e3)
MILLISECOND :: Duration(1e6)
SECOND :: Duration(1e9)

// types
Time :: odin_time.Time
Duration :: odin_time.Duration
Duration_f64 :: distinct f64
Cycles :: distinct i64
Cycles_f64 :: distinct f64

// procedures
get_cycles :: #force_inline proc "contextless" () -> Cycles {
	// NOTE: QueryThreadCycleTime(), GetThreadTimes() and similar are completely broken
	return Cycles(intrinsics.read_cycle_counter())
}

add :: #force_inline proc "contextless" (time: Time, ns: Duration) -> Time {
	return Time{time._nsec + i64(ns)}
}

sub_time :: #force_inline proc "contextless" (end, start: Time) -> Duration {
	return Duration(end._nsec - start._nsec)
}
sub_duration :: #force_inline proc "contextless" (end, start: Duration) -> Duration {
	return end - start
}
sub_cycles :: #force_inline proc "contextless" (end, start: Cycles) -> Cycles {
	return end - start
}
sub :: proc {
	sub_time,
	sub_duration,
	sub_cycles,
}

div_duration :: #force_inline proc "contextless" (a: Duration, n: int) -> Duration_f64 {
	return Duration_f64(f64(a) / f64(n))
}
div_cycles :: #force_inline proc "contextless" (a: Cycles, n: int) -> Cycles_f64 {
	return Cycles_f64(f64(a) / f64(n))
}
div :: proc {
	div_duration,
	div_cycles,
}

tprint_duration_f64 :: proc(duration_f64: Duration_f64) -> string {
	if duration_f64 >= 1e9 {
		return fmt.tprintf("%.1fs", duration_f64 / 1e9)
	} else if duration_f64 >= 1e6 {
		return fmt.tprintf("%.1fms", duration_f64 / 1e6)
	} else if duration_f64 >= 1e3 {
		return fmt.tprintf("%.1fµs", duration_f64 / 1e3)
	} else {
		return fmt.tprintf("%.1fns", duration_f64)
	}
}
tprint_cycles_f64 :: proc(cycles_f64: Cycles_f64) -> string {
	return fmt.tprintf("%.1f cy", cycles_f64)
}
tprint :: proc {
	tprint_duration_f64,
	tprint_cycles_f64,
}
