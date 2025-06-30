package benchmarks
import "../src/fmt"
import odin_fmt "core:fmt"
import odin_os "core:os"
import "core:sys/linux"
import win "core:sys/windows"

// benchmarks
assert_by_odin_fmt_assertf :: proc() {
	odin_fmt.assertf(true, "foo: %v", 13)
}
assert_by_fmt_assertf :: proc() {
	fmt.assertf(true, "foo: %v", 13)
}

print_by_odin_fmt :: proc() {
	odin_fmt.print("hi")
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
