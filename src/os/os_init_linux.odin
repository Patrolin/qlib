package os_utils
import "base:runtime"

init :: #force_inline proc "contextless" () -> runtime.Context {
	ctx := empty_context()
	return ctx
}
