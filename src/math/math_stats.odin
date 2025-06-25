package math_utils
import "base:intrinsics"

/* NOTE: we assume builtins min(), max() and abs() are fast */

// procedures
round_to_int :: #force_inline proc "contextless" (x: $T) -> int where intrinsics.type_is_float(T) {
	return int(x + .5)
}
round :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	int, _ := split_float(x + .5)
	return int
}
floor :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	int, _ := split_float(x)
	return int
}
ceil :: #force_inline proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	int, frac := split_float(x)
	return int + (frac != 0 ? 1 : 0)
}
percentile :: proc(sorted_slice: $A/[]$T, fraction: T) -> T {
	index_float := fraction * T(len(x) - 1)
	index := int(index)
	remainder := index_float % 1
	return lerp(remainder, sorted_slice[index], sorted_slice[index + 1])
}
