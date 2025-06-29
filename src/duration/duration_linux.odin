package duration_utils
import "core:sys/linux"

now :: proc "contextless" () -> Time {
	linux_time, _ := linux.clock_gettime(.REALTIME)
	ns := i64(linux_time.time_sec) * i64(SECOND) + i64(linux_time.time_nsec)
	return Time{_nsec = ns}
}
