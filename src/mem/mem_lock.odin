package mem_utils
import "base:intrinsics"

// types
Lock :: distinct bool

// procedures
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
