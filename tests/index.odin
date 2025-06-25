// odin run tests -no-crt -default-to-nil-allocator -no-thread-local
package tests
import "../src/test"
//import "alloc"
import "math"
//import "mem"
//import "threads"
//import "time"

main :: proc() {
	test.run_tests(
		"math",
		{
			{"test_count_leading_zeros", math.test_count_leading_zeros},
			{"test_log2_floor", math.test_log2_floor},
			{"test_log2_ceil", math.test_log2_ceil},
			{"test_round_floor_ceil", math.test_round_floor_ceil},
		},
	)
}
