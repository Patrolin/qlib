// odin run benchmarks -o:speed
package benchmarks
import "../src/duration"
import "../src/fmt"
import "../src/os"
import odin_os "core:os"
import "core:strings"
import "core:sys/linux"
import win "core:sys/windows"

main :: proc() {
	os.init()
	odin_os.make_directory("benchmarks/data")
	file_to_write = strings.repeat("abc\n", 4096 / 4)
	benchmarks: duration.Benchmarks

	// fmt benchmarks
	duration.append_benchmark(&benchmarks, assert_by_fmt_assertf, timeout = 0)
	duration.append_benchmark(&benchmarks, assert_by_odin_fmt_assertf, timeout = 0)
	duration.append_benchmark_group(&benchmarks)

	duration.append_benchmark(&benchmarks, assert_by_fmt_assertf)
	duration.append_benchmark(&benchmarks, assert_by_odin_fmt_assertf)
	duration.append_benchmark_group(&benchmarks)

	duration.append_benchmark(&benchmarks, print_by_write_syscall)
	duration.append_benchmark(&benchmarks, print_by_odin_fmt)
	duration.append_benchmark_group(&benchmarks)

	// write benchmarks
	duration.append_benchmark(&benchmarks, write_by_syscall)
	duration.append_benchmark(&benchmarks, write_by_odin_stdlib)
	duration.append_benchmark_group(&benchmarks)

	duration.append_benchmark(&benchmarks, write_by_syscall, init = delete_file)
	duration.append_benchmark(&benchmarks, write_by_odin_stdlib, init = delete_file)
	duration.append_benchmark_group(&benchmarks)

	// run the benchmarks
	duration.run_benchmarks(&benchmarks)
}
