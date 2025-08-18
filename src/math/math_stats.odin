package math_utils
import "base:intrinsics"

/* NOTE: we assume builtins min(), max() and abs() are fast */

// procedures
clamp_numeric :: proc(x, low, high: $T) -> T where intrinsics.type_is_numeric(T) {
	// TODO: check bytecode output of max(a, min(x, b))
	return max(low, min(x, high))
}
clamp_i32x2 :: proc(pos: i32x2, rect: AbsoluteRect) -> i32x2 {
	return i32x2{clamp(pos.x, rect.left, rect.right), clamp(pos.y, rect.top, rect.bottom)}
}
clamp :: proc {
	clamp_numeric,
	clamp_i32x2,
}
round_to_int :: #force_inline proc "contextless" (x: $T) -> int where intrinsics.type_is_float(T) {
	return int(x + .5)
}
round :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	int_part, _ := split_float(x + .5)
	return int_part
}
floor :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	int_part, _ := split_float(x)
	return int_part
}
ceil :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	int_part, frac := split_float(x)
	return int_part + (frac != 0 ? 1 : 0)
}
percentile :: proc(sorted_slice: $A/[]$T, fraction: T) -> T {
	index_float := fraction * T(len(x) - 1)
	index := int(index)
	remainder := index_float % 1
	return lerp(remainder, sorted_slice[index], sorted_slice[index + 1])
}
