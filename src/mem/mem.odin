package mem_utils
import "base:intrinsics"

// constants
// NOTE: reading from the same cache line is fine, but writing from multiple threads can lead to false sharing
CACHE_LINE_SIZE_EXPONENT :: 6
CACHE_LINE_SIZE :: 1 << CACHE_LINE_SIZE_EXPONENT

PAGE_SIZE_EXPONENT :: 12
PAGE_SIZE :: 1 << PAGE_SIZE_EXPONENT

HUGE_PAGE_SIZE_EXPONENT :: 21
HUGE_PAGE_SIZE :: 1 << HUGE_PAGE_SIZE_EXPONENT

VIRTUAL_MEMORY_TO_RESERVE :: 1 << 16

// procedures
zero_simd_64B :: proc(dest: rawptr, size: int) {
	dest := uintptr(dest)
	dest_end := dest + transmute(uintptr)(size)

	zero := (#simd[64]byte)(0)
	for dest < dest_end {
		(^#simd[64]byte)(dest)^ = zero
		dest += 64
	}
}
copy_simd_64B :: proc(dest, src: rawptr, size: int) {
	dest := uintptr(dest)
	dest_end := dest + transmute(uintptr)(size)
	src := uintptr(src)

	for dest < dest_end {
		(^#simd[64]byte)(dest)^ = (^#simd[64]byte)(src)^
		dest += 64
		src += 64
	}
}
