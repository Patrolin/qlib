package os_utils
import "../math"
import "../mem"
import "base:runtime"
import odin_os "core:os"
import win "core:sys/windows"

// constants
ATTACH_PARENT_PROCESS :: transmute(win.DWORD)i32(-1)
STD_INPUT_HANDLE :: transmute(win.DWORD)i32(-10)
STD_OUTPUT_HANDLE :: transmute(win.DWORD)i32(-11)
STD_ERROR_HANDLE :: transmute(win.DWORD)i32(-12)

// imports
foreign import kernel32 "system:kernel32.lib"
@(default_calling_convention = "std")
foreign kernel32 {
	@(private)
	AttachConsole :: proc(dwProcessId: win.DWORD) -> win.BOOL ---
}

// procedures
init :: #force_inline proc "contextless" () -> runtime.Context {
	ctx := empty_context()
	context = ctx
	// page fault handler
	mem.init_page_fault_handler()
	// console
	AttachConsole(ATTACH_PARENT_PROCESS)
	odin_os.stdin = odin_os.Handle(win.GetStdHandle(STD_INPUT_HANDLE))
	odin_os.stdout = odin_os.Handle(win.GetStdHandle(STD_OUTPUT_HANDLE))
	odin_os.stderr = odin_os.Handle(win.GetStdHandle(STD_ERROR_HANDLE))
	win.SetConsoleOutputCP(win.CODEPAGE(win.CP_UTF8))
	// _time_divisor
	query_performance_frequency: win.LARGE_INTEGER
	assert(bool(win.QueryPerformanceFrequency(&query_performance_frequency)))
	assert(1e9 % i64(query_performance_frequency) == 0)
	info._time_multiplier = 1e9 / i64(query_performance_frequency)
	assert(win.timeBeginPeriod(1) == win.TIMERR_NOERROR) // set min sleep timeout (from 15ms) to 1ms
	// page_size, large_page_size
	systemInfo: win.SYSTEM_INFO
	win.GetSystemInfo(&systemInfo)
	info.page_size = int(systemInfo.dwAllocationGranularity)
	info.large_page_size = int(win.GetLargePageMinimum()) // NOTE: windows large pages require nonsense: https://stackoverflow.com/questions/42354504/enable-large-pages-in-windows-programmatically
	// logical_core_count
	system_info: win.SYSTEM_INFO
	win.GetSystemInfo(&system_info)
	info.logical_core_count = int(system_info.dwNumberOfProcessors) // NOTE: this cannot go above 64
	// window_border
	window_border: win.RECT
	win.AdjustWindowRectEx(&window_border, win.WS_OVERLAPPEDWINDOW, false, 0)
	info.window_border = math.AbsoluteRect {
		-window_border.left,
		-window_border.top,
		window_border.right,
		window_border.bottom,
	}

	return ctx
}
