package duration_utils
import "../os"
import "base:intrinsics"
import "core:fmt"
import win "core:sys/windows"

now :: proc "contextless" () -> Time {
	file_time: win.FILETIME
	win.GetSystemTimePreciseAsFileTime(&file_time)
	windows_time := u64(transmute(u64le)file_time)
	ns := (windows_time - 116444736000000000) * 100
	return Time{i64(ns)}
}

sleep_ns :: proc(ns: Duration) {
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
}
