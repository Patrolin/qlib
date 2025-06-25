package math_utils
import "base:intrinsics"
import core_math "core:math"

// constants
PI :: core_math.PI
TAU :: core_math.TAU

// types
/* NOTE: Odin vector types (.xyzw, .rgba)
	TODO: how does this interact with #simd?
*/
i32x2 :: [2]i32 // 8 B
i32x3 :: [3]i32 // 12 B
i32x4 :: [4]i32 // 16 B
f32x2 :: [2]f32 // 8 B
f32x3 :: [3]f32 // 12 B
f32x4 :: [4]f32 // 16 B
AbsoluteRect :: struct {
	left, top, right, bottom: i32,
}
RelativeRect :: struct {
	left, top, width, height: i32,
}

// procedures
sin :: core_math.sin
cos :: core_math.cos
mod :: core_math.mod
sqrt :: core_math.sqrt
exp :: core_math.exp
pow :: core_math.pow
norm :: proc(vector: [$N]$T) -> f32 {
	acc := f32(0)
	for v in vector {acc += f32(v * v)}
	return sqrt(acc)
}
sincos :: core_math.sincos
absolute_rect :: #force_inline proc "contextless" (rect: RelativeRect) -> AbsoluteRect {
	return {rect.left, rect.top, rect.left + rect.width, rect.top + rect.height}
}
relative_rect :: #force_inline proc "contextless" (rect: AbsoluteRect) -> RelativeRect {
	return {rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top}
}
in_bounds :: proc(pos: i32x2, rect: AbsoluteRect) -> bool {
	return(
		(pos.x >= rect.left) &
		(pos.x <= rect.right) &
		(pos.y >= rect.bottom) &
		(pos.y <= rect.top) \
	)
}
clamp :: proc {
	clamp_int,
	clamp_i32x2,
}
clamp_int :: proc(x, min, max: $T) -> T where intrinsics.type_is_numeric(T) {
	// TODO: check bytecode output of max(a, min(x, b))
	x := x + (min - x) * T(x < min)
	x = x + (max - x) * T(x > max)
	return x
}
clamp_i32x2 :: proc(pos: i32x2, rect: AbsoluteRect) -> i32x2 {
	return {clamp(pos.x, rect.left, rect.right), clamp(pos.y, rect.top, rect.bottom)}
}
