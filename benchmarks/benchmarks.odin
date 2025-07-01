// odin run benchmarks -o:speed
package benchmarks
import "../src/fmt"
import "../src/os"
import "../src/timing"
import odin_os "core:os"
import "core:strings"
import "core:sys/linux"
import win "core:sys/windows"

main :: proc() {
	os.init()
	odin_os.make_directory("benchmarks/data")
	file_to_write = strings.repeat("abc\n", 4096 / 4)
	benchmarks: timing.Benchmarks

	// timing benchmarks
	timing.append_benchmark(&benchmarks, get_time)
	timing.append_benchmark(&benchmarks, get_duration)
	timing.append_benchmark(&benchmarks, get_cycles)
	timing.append_benchmark_group(&benchmarks)

	// fmt benchmarks
	/* NOTE: first runs are prone to not being in cache (resulting in 1000x slowdown)
		and to being relocated in the executable when changing the procedure name, e.g. "assertf" -> "assertf2"
		(resulting in a 2x slowdown), and thus should never be used.
	*/
	timing.append_benchmark(&benchmarks, do_nothing, timeout = 0)
	timing.append_benchmark(&benchmarks, assert_by_fmt_assertf, timeout = 0)
	timing.append_benchmark(&benchmarks, assert_by_odin_fmt_assertf, timeout = 0)
	timing.append_benchmark_group(&benchmarks)

	timing.append_benchmark(&benchmarks, do_nothing)
	timing.append_benchmark(&benchmarks, assert_by_fmt_assertf)
	timing.append_benchmark(&benchmarks, assert_by_odin_fmt_assertf)
	timing.append_benchmark_group(&benchmarks)

	timing.append_benchmark(&benchmarks, print_by_write_syscall)
	timing.append_benchmark(&benchmarks, print_by_odin_fmt)
	timing.append_benchmark_group(&benchmarks)

	// write benchmarks
	timing.append_benchmark(&benchmarks, write_by_syscall)
	timing.append_benchmark(&benchmarks, write_by_odin_stdlib)
	timing.append_benchmark_group(&benchmarks)

	timing.append_benchmark(&benchmarks, write_by_syscall, init = delete_file)
	timing.append_benchmark(&benchmarks, write_by_odin_stdlib, init = delete_file)
	timing.append_benchmark_group(&benchmarks)

	// run the benchmarks
	timing.run_benchmarks(&benchmarks)
}
