package tests
import "../src/fmt"
import "base:runtime"
import core_fmt "core:fmt"

test_fmt :: proc() {
	context.allocator = runtime.nil_allocator()
	context.temp_allocator = runtime.nil_allocator()
	fmt.printf("test: %v", 13)
	core_fmt.printfln("test: %v", 13)
}
