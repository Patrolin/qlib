package mem_utils
import "../math"
import win "core:sys/windows"

// procedures
init_page_fault_handler :: #force_inline proc "contextless" () {
	win.SetUnhandledExceptionFilter(_page_fault_exception_handler)
}
_page_fault_exception_handler :: proc "system" (exception: ^win.EXCEPTION_POINTERS) -> win.LONG {
	DEBUG :: false
	when DEBUG {context = runtime.default_context()}
	if exception.ExceptionRecord.ExceptionCode == win.EXCEPTION_ACCESS_VIOLATION {
		// is_writing := exception.ExceptionRecord.ExceptionInformation[0]
		ptr := exception.ExceptionRecord.ExceptionInformation[1]

		commited_ptr := win.VirtualAlloc(ptr, 4096, win.MEM_COMMIT, win.PAGE_READWRITE)
		when DEBUG {
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
// TODO: don't use page_alloc() outside of utils/alloc
page_alloc :: proc(size: math.Size, commit_immediately := true) -> []byte {
	ptr := VirtualAlloc2(
		nil,
		nil,
		win.SIZE_T(size),
		win.MEM_RESERVE | (commit_immediately ? win.MEM_COMMIT : 0),
		win.PAGE_READWRITE,
		nil,
		0,
	)
	return (cast([^]byte)ptr)[:size]
}
// ?TODO: remove this
page_alloc_aligned :: proc(
	size: math.Size,
	alignment: math.Size,
	loc := #caller_location,
) -> []byte {
	address_requirement := MEM_ADDRESS_REQUIREMENTS {
		Alignment = win.SIZE_T(alignment),
	}
	alloc_params: []MEM_EXTENDED_PARAMETER = {
		MEM_EXTENDED_PARAMETER {
			Type = .MemExtendedParameterAddressRequirements,
			Pointer = &address_requirement,
		},
	}
	ptr := VirtualAlloc2(
		nil,
		nil,
		win.SIZE_T(size),
		win.MEM_RESERVE | win.MEM_COMMIT,
		win.PAGE_READWRITE,
		&alloc_params[0],
		u32(len(alloc_params)),
	)
	assert(ptr != nil, "Failed to allocate", loc = loc)
	return (cast([^]byte)ptr)[:size]
}
page_free :: proc(ptr: rawptr) -> b32 {
	return b32(win.VirtualFree(ptr, 0, win.MEM_RELEASE))
}

// VirtualAlloc2()
foreign import onecorelib "system:onecore.lib"
@(default_calling_convention = "std")
foreign onecorelib {
	VirtualAlloc2 :: proc(Process: win.HANDLE, BaseAddress: win.PVOID, Size: win.SIZE_T, AllocationType: win.ULONG, PageProtection: win.ULONG, ExtendedParameters: ^MEM_EXTENDED_PARAMETER, ParameterCount: win.ULONG) -> win.LPVOID ---
}
// address params
MEM_ADDRESS_REQUIREMENTS :: struct {
	LowestStartingAddress: win.PVOID,
	HighestEndingAddress:  win.PVOID,
	Alignment:             win.SIZE_T,
}
// extended params
MEM_EXTENDED_PARAMETER :: struct {
	using _: bit_field win.DWORD64 {
		Type:     MEM_EXTENDED_PARAMETER_TYPE | MEM_EXTENDED_PARAMETER_TYPE_BIT_SIZE,
		Reserved: win.DWORD64                 | 64 - MEM_EXTENDED_PARAMETER_TYPE_BIT_SIZE,
	},
	using _: struct #raw_union {
		ULong64: win.DWORD64,
		Pointer: win.PVOID,
		Size:    win.SIZE_T,
		Handle:  win.HANDLE,
		ULong:   win.DWORD,
	},
}
MEM_EXTENDED_PARAMETER_TYPE_BIT_SIZE :: 8
MEM_EXTENDED_PARAMETER_TYPE :: enum win.DWORD64 {
	MemExtendedParameterAddressRequirements = 1,
	MemExtendedParameterNumaNode            = 2,
	MemExtendedParameterAttributeFlags      = 5,
}
MemExtendedParameterAttributeFlagsEnum :: enum win.DWORD64 {
	MEM_EXTENDED_PARAMETER_NONPAGED       = 0x2,
	MEM_EXTENDED_PARAMETER_NONPAGED_LARGE = 0x8,
	MEM_EXTENDED_PARAMETER_NONPAGED_HUGE  = 0x10,
	MEM_EXTENDED_PARAMETER_EC_CODE        = 0x40,
}
