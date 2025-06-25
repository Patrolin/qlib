package test_time
import "../../src/os"
import "../../src/time"
import "core:fmt"

test_sleep_ns :: proc() {
	// TODO: test random amounts to sleep?
	for i := 0; i < 5; i += 1 {
		time.sleep_ns(4 * time.MILLISECOND)
	}
}
