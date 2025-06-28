package mem_utils
import "../math"
import "base:runtime"
import "core:fmt"
import win "core:sys/windows"

DEBUG_VIRTUAL :: false

// procedures
init_page_fault_handler :: #force_inline proc "contextless" () {
	win.SetUnhandledExceptionFilter(_page_fault_exception_handler)
}
_page_fault_exception_handler :: proc "system" (exception: ^win.EXCEPTION_POINTERS) -> win.LONG {
	when DEBUG_VIRTUAL {context = runtime.default_context()}
	if exception.ExceptionRecord.ExceptionCode == win.EXCEPTION_ACCESS_VIOLATION {
		// is_writing := exception.ExceptionRecord.ExceptionInformation[0]
		ptr := exception.ExceptionRecord.ExceptionInformation[1]
		page_ptr := rawptr(uintptr(ptr) & ~uintptr(PAGE_SIZE - 1))

		commited_ptr := win.VirtualAlloc(page_ptr, 4096, win.MEM_COMMIT, win.PAGE_READWRITE)
		when DEBUG_VIRTUAL {
			//fmt.printfln("EXCEPTION_ACCESS_VIOLATION: %v", exception.ExceptionRecord)
			fmt.printfln(
				"EXCEPTION_ACCESS_VIOLATION, ptr: %v, commited_ptr: %v",
				ptr,
				commited_ptr,
			)
		}

		ERROR_INVALID_ADDRESS :: 487
		return(
			ptr != nil && commited_ptr != nil ? win.EXCEPTION_CONTINUE_EXECUTION : win.EXCEPTION_EXECUTE_HANDLER \
		)
	}
	return win.EXCEPTION_EXECUTE_HANDLER
}
page_reserve :: proc(size: math.Size) -> []byte {
	ptr := win.VirtualAlloc(nil, win.SIZE_T(size), win.MEM_RESERVE, win.PAGE_READWRITE)
	return (cast([^]byte)ptr)[:size]
}
page_free :: proc(ptr: rawptr) -> b32 {
	return b32(win.VirtualFree(ptr, 0, win.MEM_RELEASE))
}
