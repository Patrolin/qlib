package math_utils
import "base:intrinsics"

/* mostly copy-paste from "core:math" */

// procedures
split_float_f16 :: proc "contextless" (x: f16) -> (int: f16, frac: f16) {
	MASK: u16 : 0x1f
	SHIFT: u16 : 16 - 6
	BIAS: u16 : 0xf

	negate := x < 0
	x := negate ? -x : x

	if x < 1 {return 0, negate ? -x : x}

	i := transmute(u16)x
	e := (i >> SHIFT) & MASK - BIAS

	if e < SHIFT {i &~= 1 << (SHIFT - e) - 1}
	int = transmute(f16)i
	frac = x - int
	return negate ? -int : int, negate ? -frac : frac
}
split_float_f32 :: proc "contextless" (x: f32) -> (int: f32, frac: f32) {
	MASK: u32 : 0xff
	SHIFT: u32 : 32 - 9
	BIAS: u32 : 0x7f

	negate := x < 0
	x := negate ? -x : x

	if x < 1 {return 0, negate ? -x : x}

	i := transmute(u32)x
	e := (i >> SHIFT) & MASK - BIAS

	if e < SHIFT {i &~= 1 << (SHIFT - e) - 1}
	int = transmute(f32)i
	frac = x - int
	return negate ? -int : int, negate ? -frac : frac
}
split_float_f64 :: proc "contextless" (x: f64) -> (int: f64, frac: f64) {
	MASK: u64 : 0x7ff
	SHIFT: u64 : 64 - 12
	BIAS: u64 : 0x3ff

	negate := x < 0
	x := negate ? -x : x

	if x < 1 {return 0, negate ? -x : x}

	i := transmute(u64)x
	e := (i >> SHIFT) & MASK - BIAS

	if e < SHIFT {i &~= 1 << (SHIFT - e) - 1}
	int = transmute(f64)i
	frac = x - int
	return negate ? -int : int, negate ? -frac : frac
}
split_float :: proc {
	split_float_f16,
	split_float_f32,
	split_float_f64,
}
