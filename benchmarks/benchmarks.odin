// odin run benchmarks
package main
import "../src/duration"
import "../src/os"
import "core:fmt"
import odin_os "core:os"
import "core:sys/linux"
import win "core:sys/windows"

print_by_odin_fmt :: proc() {
	fmt.print("hi")
}
print_by_write_syscall :: proc() {
	buf: [1024]byte
	buf[0] = 'h'
	buf[1] = 'i'
	buf[2] = 0
	when ODIN_OS == .Windows {
		win.WriteFile(win.HANDLE(odin_os.stdout), &buf, 2, nil, nil)
	} else when ODIN_OS == .Linux {
		linux.write(linux.STDOUT_FILENO, buf[:2])
	} else {
		#assert(false, "not implemented")
	}
}

main :: proc() {
	os.init()
	benchmarks: duration.Benchmarks
	duration.append_benchmark(&benchmarks, print_by_odin_fmt)
	duration.append_benchmark(&benchmarks, print_by_write_syscall)
	duration.run_benchmarks(&benchmarks)
}
