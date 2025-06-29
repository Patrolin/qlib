// odin run benchmarks
package main
import "../src/duration"
import "../src/os"
import "core:fmt"
import odin_os "core:os"
import win "core:sys/windows"

print_by_odin_fmt :: proc() {
	fmt.print("hi")
}
print_by_WriteFile :: proc() {
	buf: [1024]byte
	buf[0] = 'h'
	buf[1] = 'i'
	buf[2] = 0
	win.WriteFile(win.HANDLE(odin_os.stdout), &buf, 2, nil, nil)
}

main :: proc() {
	os.init()
	benchmarks: duration.Benchmarks
	duration.append_benchmark(&benchmarks, print_by_odin_fmt)
	duration.append_benchmark(&benchmarks, print_by_WriteFile)
	duration.run_benchmarks(&benchmarks)
}
