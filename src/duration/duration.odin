package duration_utils
import "../math"
import "../os"
import "base:intrinsics"
import "core:fmt"
import win "core:sys/windows"
import core_time "core:time"

// constants
NANOSECOND :: Duration(1)
MICROSECOND :: Duration(1e3)
MILLISECOND :: Duration(1e6)
SECOND :: Duration(1e9)

// types
Time :: core_time.Time
Duration :: core_time.Duration
Cycles :: distinct i64

// procedures
now :: proc "contextless" () -> Time {
	when ODIN_OS == .Windows {
		counter: win.LARGE_INTEGER
		win.QueryPerformanceCounter(&counter)
		ns := i64(counter) * os.info._time_multiplier
	} else {
		#assert(false, "Not implemented")
	}
	return Time{ns}
}
now_cycles :: #force_inline proc "contextless" () -> Cycles {
	// NOTE: QueryThreadCycleTime(), GetThreadTimes() and similar are completely broken
	return Cycles(intrinsics.read_cycle_counter())
}

add :: #force_inline proc "contextless" (time: Time, offset: Duration) -> Time {
	return Time{time._nsec + i64(offset)}
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

sleep_ns :: proc(ns: Duration) {
	when ODIN_OS == .Windows {
		end_time := add(now(), ns)
		diff := sub(end_time, now())
		//fmt.printfln("  0: %v ns", diff)
		OS_PREEMPT_FREQUENCY :: 500 * MICROSECOND
		MAX_OS_THREAD_WAIT :: 3 * OS_PREEMPT_FREQUENCY
		for diff > MAX_OS_THREAD_WAIT {
			ms_to_sleep := max(0, diff / MILLISECOND - 2)
			win.Sleep(u32(ms_to_sleep))
			diff = sub(end_time, now())
			//fmt.printfln("1.a: %v ns (slept for %v ms)", diff, ms_to_sleep)
		}
		for diff > 0 {
			intrinsics.cpu_relax()
			diff = sub(end_time, now())
		}
		//fmt.printfln("  2: %v ns", diff)
		fmt.assertf(diff == 0, "diff: %v", diff)
	} else {
		#assert(false, "Not implemented")
	}
}
