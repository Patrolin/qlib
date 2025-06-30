// odin run benchmarks -o:speed
package benchmarks
import "../src/duration"
import "../src/os"
import "core:fmt"
import odin_os "core:os"
import "core:strings"
import "core:sys/linux"
import win "core:sys/windows"

main :: proc() {
	os.init()
	odin_os.make_directory("benchmarks/data")
	file_to_write = strings.repeat("abc\n", 4096 / 4)

	benchmarks: duration.Benchmarks
	// fmt
	duration.append_benchmark(&benchmarks, print_by_write_syscall)
	duration.append_benchmark(&benchmarks, print_by_odin_fmt)
	// write
	duration.append_benchmark(&benchmarks, write_by_syscall)
	duration.append_benchmark(&benchmarks, write_by_odin_stdlib)
	duration.append_benchmark(&benchmarks, write_by_syscall, delete_file)
	duration.append_benchmark(&benchmarks, write_by_odin_stdlib, delete_file)

	duration.run_benchmarks(&benchmarks)
}
