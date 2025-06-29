package duration_utils
import "../math"
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
Cycles :: distinct i64

// procedures
now_cycles :: #force_inline proc "contextless" () -> Cycles {
	// NOTE: QueryThreadCycleTime(), GetThreadTimes() and similar are completely broken
	return Cycles(intrinsics.read_cycle_counter())
}

add :: #force_inline proc "contextless" (time: Time, ns: Duration) -> Time {
	return Time{time._nsec + i64(ns)}
}

sub_time :: #force_inline proc "contextless" (end, start: Time) -> Duration {
	return Duration(end._nsec - start._nsec)
}
sub_cycles :: #force_inline proc "contextless" (end, start: Cycles) -> Cycles {
	return end - start
}
sub :: proc {
	sub_time,
	sub_cycles,
}

div_duration :: #force_inline proc "contextless" (a: Duration, n: i64) -> Duration {
	return Duration(math.round_to_int(f64(a) / f64(n)))
}
div_cycles :: #force_inline proc "contextless" (a: Cycles, n: i64) -> Cycles {
	return Cycles(math.round_to_int(f64(a) / f64(n)))
}
div :: proc {
	div_duration,
	div_cycles,
}
