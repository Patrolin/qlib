package duration_utils
import "core:sys/linux"

now :: proc "contextless" () -> Time {
	linux_time := linux.clock_gettime(.REALTIME)
	ns := i64(linux_time.time_sec) * SECOND + i64(linux_time.time_nsec)
	return Time{_nsec = ns}
}
