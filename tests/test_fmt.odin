package tests
import "../src/fmt"
import "base:runtime"
import odin_fmt "core:fmt"

test_fmt :: proc() {
	context.allocator = runtime.nil_allocator()
	context.temp_allocator = runtime.nil_allocator()
	fmt.printf("test: %v", 13)
	odin_fmt.printfln("test: %v", 13)
}
