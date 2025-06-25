package repro
import "../src/math"
import "core:fmt"

main :: proc() {
	fmt.printfln("test: %v", math.align_backward(rawptr(uintptr(1)), 64))
}
