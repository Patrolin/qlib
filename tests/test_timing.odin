package tests
import "../src/fmt"
import "../src/timing"

test_timings :: proc() {
	fmt.printfln("now: %v", timing.get_time())
	assert(timing.get_time()._nsec != 0)
	assert(timing.get_duration() != 0)
	assert(timing.get_cycles() != 0)
}
test_sleep_ns :: proc() {
	// TODO: test random amounts to sleep?
	for i := 0; i < 5; i += 1 {
		timing.sleep_ns(4 * timing.MILLISECOND)
	}
}
