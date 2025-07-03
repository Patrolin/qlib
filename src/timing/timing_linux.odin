package duration_utils
import "core:sys/linux"

get_time :: proc "contextless" () -> Time {
	linux_time, _ := linux.clock_gettime(.REALTIME)
	ns := i64(linux_time.time_sec) * i64(SECOND) + i64(linux_time.time_nsec)
	return Time{_nsec = ns}
}
get_duration :: proc "contextless" () -> Duration {
	linux_time, _ := linux.clock_gettime(.MONOTONIC)
	ns := i64(linux_time.time_sec) * i64(SECOND) + i64(linux_time.time_nsec)
	return Duration(ns)
}

/* TODO: How to get performance counters with linux syscalls?
	- perf_event_open syscall
*/
