package lib_mem
import "base:intrinsics"

// constants
// NOTE: SSD block sizes are 512B or 4KiB
VIRTUAL_MEMORY_TO_RESERVE :: 1 << 16

PAGE_SIZE_EXPONENT :: 12
PAGE_SIZE :: 1 << PAGE_SIZE_EXPONENT

HUGE_PAGE_SIZE_EXPONENT :: 21
HUGE_PAGE_SIZE :: 1 << HUGE_PAGE_SIZE_EXPONENT

// NOTE: multiple threads reading from the same cache line is fine, but writing can lead to false sharing
CACHE_LINE_SIZE_EXPONENT :: 6
CACHE_LINE_SIZE :: 1 << CACHE_LINE_SIZE_EXPONENT

// types
Lock :: distinct bool

// lock procedures
mfence :: #force_inline proc "contextless" () {
	intrinsics.atomic_thread_fence(.Seq_Cst)
}
@(require_results)
get_lock_or_error :: #force_inline proc "contextless" (lock: ^Lock) -> (ok: bool) {
	old_value := intrinsics.atomic_exchange(lock, true)
	return old_value == false
}
get_lock :: #force_inline proc "contextless" (lock: ^Lock) {
	for {
		old_value := intrinsics.atomic_exchange(lock, true)
		if intrinsics.expect(old_value == false, true) {return}
		intrinsics.cpu_relax()
	}
	mfence()
}
release_lock :: #force_inline proc "contextless" (lock: ^Lock) {
	intrinsics.atomic_store(lock, false)
}

// copy procedures
copy_slow :: proc(src: rawptr, size: int, dest: rawptr) {
	dest := uintptr(dest)
	dest_end := dest + transmute(uintptr)(size)
	src := uintptr(src)
	for dest < dest_end {
		(^byte)(dest)^ = (^byte)(src)^
		dest += 1
		src += 1
	}
}
zero_simd_64B :: proc(dest: rawptr, size: int) {
	dest := uintptr(dest)
	dest_end := dest + transmute(uintptr)(size)

	zero := (#simd[64]byte)(0)
	for dest < dest_end {
		(^#simd[64]byte)(dest)^ = zero
		dest += 64
	}
}
copy_simd_64B :: proc(src: rawptr, size: int, dest: rawptr) {
	dest := uintptr(dest)
	dest_end := dest + transmute(uintptr)(size)
	src := uintptr(src)

	for dest < dest_end {
		(^#simd[64]byte)(dest)^ = (^#simd[64]byte)(src)^
		dest += 64
		src += 64
	}
}
