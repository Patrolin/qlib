package test_time
import "../../src/os"
import "../../src/test"
import "../../src/time"
import "core:fmt"
import "core:testing"

@(test)
test_sleep_ns :: proc(t: ^testing.T) {
	test.start_test(t)
	test.set_fail_timeout(time.SECOND)

	os.init()
	// TODO: test random amounts to sleep?
	for i := 0; i < 5; i += 1 {
		time.sleep_ns(4 * time.MILLISECOND)
	}

	test.end_test()
}
