// odin run tests/fmt -default-to-nil-allocator
package test_fmt
import "../../src/fmt"
import "base:runtime"
import core_fmt "core:fmt"

main :: proc() {
	context.allocator = runtime.nil_allocator()
	context.temp_allocator = runtime.nil_allocator()
	fmt.printf("test: %v", 13)
	core_fmt.printfln("test: %v", 13)
}
