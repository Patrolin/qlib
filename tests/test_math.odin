package tests
import "../src/math"
import "../src/test"

test_round_floor_ceil :: proc() {
	// TODO: also test negative numbers
	test.expect(math.round(1.9) == 2.0)
	test.expect(math.round(1.5) == 2.0)
	test.expect(math.round(1.0) == 1.0)

	test.expect(math.round_to_int(1.9) == 2)
	test.expect(math.round_to_int(1.5) == 2)
	test.expect(math.round_to_int(1.0) == 1)

	test.expect(math.floor(1.9) == 1.0)
	test.expect(math.floor(1.5) == 1.0)
	test.expect(math.floor(1.0) == 1.0)

	test.expect(math.ceil(1.9) == 2.0)
	test.expect(math.ceil(1.5) == 2.0)
	test.expect(math.ceil(1.0) == 1.0)
}

test_count_leading_zeros :: proc() {
	for test_case in ([]test.Case(u64, u64){{0, 64}, {1, 63}, {2, 62}, {3, 62}}) {
		using test_case
		test.expect_case(test_case, math.count_leading_zeros(key))
	}
	for test_case in ([]test.Case(u8, u8){{0, 8}, {1, 7}, {2, 6}, {3, 6}}) {
		using test_case
		test.expect_case(test_case, math.count_leading_zeros(key))
	}
}

test_log2_floor :: proc() {
	test_cases := []test.Case(uint, uint) {
		{0, 0},
		{1, 0},
		{2, 1},
		{3, 1},
		{4, 2},
		{7, 2},
		{4096, 12},
	}
	for test_case in test_cases {
		using test_case
		test.expect_case(test_case, math.log2_floor(key))
	}
}
test_log2_ceil :: proc() {
	for test_case in ([]test.Case(u64, u64) {
			{0, 0},
			{1, 0},
			{2, 1},
			{3, 2},
			{4, 2},
			{7, 3},
			{4096, 12},
		}) {
		using test_case
		test.expect_case(test_case, math.log2_ceil(key))
	}
}
