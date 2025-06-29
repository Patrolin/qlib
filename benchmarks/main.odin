package main
import "../src/duration"
import "../src/os"
import "core:fmt"
import core_os "core:os"
import win "core:sys/windows"

print_by_fmt :: proc() {
	fmt.print("hi")
}
print_by_write_file :: proc() {
	buf: [1024]byte
	buf[0] = 'h'
	buf[1] = 'i'
	buf[2] = 0
	win.WriteFile(win.HANDLE(core_os.stdout), &buf, 2, nil, nil)
}

main :: proc() {
	os.init()
	benchmarks: duration.Benchmarks
	duration.append_benchmark(&benchmarks, print_by_fmt)
	duration.append_benchmark(&benchmarks, print_by_write_file)
	duration.run_benchmarks(&benchmarks)
}
