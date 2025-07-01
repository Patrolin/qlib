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

	/* NOTE: first runs are prone to being relocated in the executable (randomly resulting in a 40x slowdown), and thus should never be used. */
	timing.run_benchmark(&benchmarks, do_nothing, "do_nothing")
	timing.run_benchmark(&benchmarks, assert_by_odin_fmt_assertf, "assert_by_odin_fmt_assertf", timeout = 0)
	timing.run_benchmark(&benchmarks, assert_by_fmt_assertf, "assert_by_fmt_assertf", timeout = 0)
	timing.run_benchmark(&benchmarks, assert_by_odin_fmt_assertf, "assert_by_odin_fmt_assertf")
	timing.run_benchmark(&benchmarks, assert_by_fmt_assertf, "assert_by_fmt_assertf")
	timing.run_benchmark_group(&benchmarks)

	// TODO: rewrite these so they can be inlined // TODO: how do we tell odin to not discard a value??
	// timing benchmarks
	timing.run_benchmark(&benchmarks, get_cycles, "get_cycles")
	timing.run_benchmark(&benchmarks, get_duration, "get_duration")
	timing.run_benchmark(&benchmarks, get_time, "get_time")
	timing.run_benchmark_group(&benchmarks)

	// fmt benchmarks
	/*
	timing.run_benchmark(&benchmarks, print_by_write_syscall, "print_by_write_syscall")
	timing.run_benchmark(&benchmarks, print_by_odin_fmt, "print_by_odin_fmt")
	timing.run_benchmark_group(&benchmarks)
	*/

	// write benchmarks
	timing.run_benchmark(&benchmarks, write_file_by_syscall, "write_file_by_syscall")
	timing.run_benchmark(&benchmarks, write_file_by_odin_stdlib, "write_file_by_odin_stdlib")
	timing.run_benchmark_group(&benchmarks)

	// run the benchmarks
	timing.print_benchmarks(&benchmarks)
}
