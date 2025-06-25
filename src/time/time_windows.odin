package time_utils
import "../os"
import "../test"
import "base:intrinsics"
import win "core:sys/windows"

// procedures
time :: proc "contextless" () -> Duration {
	counter: win.LARGE_INTEGER
	win.QueryPerformanceCounter(&counter)
	return Duration(int(counter) * (int(SECOND) / os.info._time_divisor))
}
sleep_ns :: proc(ns: Duration) {
	when ODIN_OS == .Windows {
		end_time := time() + ns
		diff := end_time - time()
		//fmt.printfln("  0: %v ns", diff)
		OS_PREEMPT_FREQUENCY :: 500 * MICROSECOND
		MAX_OS_THREAD_WAIT :: 3 * OS_PREEMPT_FREQUENCY
		for diff > MAX_OS_THREAD_WAIT {
			ms_to_sleep := max(0, diff / MILLISECOND - 2)
			win.Sleep(u32(ms_to_sleep))
			diff = end_time - time()
			//fmt.printfln("1.a: %v ns (slept for %v ms)", diff, ms_to_sleep)
		}
		for diff > 0 {
			intrinsics.cpu_relax()
			diff = end_time - time()
		}
		//fmt.printfln("  2: %v ns", diff)
		test.expectf(diff == 0, "diff: %v", diff)
	} else {
		#assert(false, "Not implemented")
	}
}
