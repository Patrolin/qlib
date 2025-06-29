package tests
import "../src/duration"
import "core:fmt"

test_now :: proc() {
	fmt.printfln("now: %v", duration.now())
	assert(duration.now()._nsec != 0)
	assert(duration.now_cycles() != 0)
}
test_sleep_ns :: proc() {
	// TODO: test random amounts to sleep?
	for i := 0; i < 5; i += 1 {
		duration.sleep_ns(4 * duration.MILLISECOND)
	}
}
