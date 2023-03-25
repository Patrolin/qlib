// 14 KB hello world
//#pragma comment(linker, "/nodefaultlib:libcmt.lib")
//#pragma comment(linker, "/nodefaultlib:msvcmrt.lib")
//#pragma comment(linker, "/nodefaultlib:msvcrt.lib")

//#define USE_NOLIBS // TODO
#include <windows.h>
#pragma comment(linker, "/defaultlib:user32.lib")
#pragma comment(linker, "/defaultlib:kernel32.lib")

#include "int.h"

// print
void* talloc(uint size);
HANDLE stdout = 0; // init
uint cstrCount(const char* start) {
    const char* end = start;
    while (*end != 0) { end++; };
    return end - start;
}
// TODO: use String everywhere?
void debugPrint(const char* cstr) {
    WriteConsoleA(stdout, cstr, cstrCount(cstr), 0, 0);
}
const uint U64_MAX_BASE10_DIGITS = 20;
void debugPrintNum(uint number) {
    char format[U64_MAX_BASE10_DIGITS+1];
    char* curr = format + U64_MAX_BASE10_DIGITS+1;
    *--curr = 0;
    do {
        *--curr = '0' + (number % 10);
        number /= 10;
    } while (number > 0);
    WriteConsoleA(stdout, curr, U64_MAX_BASE10_DIGITS-(curr-format), 0, 0);
}
struct String {
    uint count;
    char* data;
    // TODO: allow allocating on stack
    static String* fromC(const char* cstr) {
        String* str = (String*)talloc(sizeof(String));
        str->count = cstrCount(cstr);
        str->data = (char*)cstr;
        return str;
    }
};
void print(String* str) {
    MessageBoxA(0, str->data, "Message", MB_OK|MB_ICONINFORMATION);
}

// alloc
#define ArrayCount(Array) (sizeof(Array) / sizeof((Array)[0]))
#define kiloBytes(n) ((uint)n*1024)
#define megaBytes(n) (kiloBytes(n)*1024)
#define gigaBytes(n) (megaBytes(n)*1024)

struct TAlloc {
    u8* start = 0;
    uint size = 0;
    uint data_size = 0;
};
TAlloc _talloc = {};
void* talloc(uint size) {
    uint new_data_size = _talloc.data_size + size;
    if (new_data_size > _talloc.size) {
        uint new_size = _talloc.size + kiloBytes(1);
        _talloc.start = (u8*)VirtualAlloc(_talloc.start, new_size, MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE);
        if (_talloc.start == 0) {
            debugPrint("AllocError");
            Sleep(1000);
            ExitProcess(1);
        }
        _talloc.size = new_size;
    }
    void* data = _talloc.start + _talloc.data_size;
    _talloc.data_size = new_data_size;
    return data;
}

// init
void qclibInit() {
    AllocConsole();
    stdout = GetStdHandle(-11);
}

// crt
//#undef NO_STDLIB
//#define NO_STDLIB
#ifdef NO_STDLIB
    // constructors
    typedef int (__cdecl *_PIFV)(void);
    typedef void (__cdecl *_PVFV)(void);
    #define _CRTALLOC(name) __declspec(allocate(name))
    #pragma comment(linker, "/merge:.CRT=.rdata")

    // C constructors
    #pragma section(".CRT$XIA", long, read)
    _CRTALLOC(".CRT$XIA") _PIFV __xi_a[] = { 0 };
    #pragma section(".CRT$XIZ", long, read)
    _CRTALLOC(".CRT$XIZ") _PIFV __xi_z[] = { 0 };

    // C++ constructors
    #pragma section(".CRT$XCA", long, read)
    _CRTALLOC(".CRT$XCA") _PVFV __xc_a[] = { 0 };
    #pragma section(".CRT$XCZ", long, read)
    _CRTALLOC(".CRT$XCZ") _PVFV __xc_z[] = { 0 };

    void __cdecl _initterm(_PVFV * pfbegin, _PVFV * pfend) {
        while ( pfbegin < pfend ) {
            if ( *pfbegin != 0 )
                (**pfbegin)();
            ++pfbegin;
        }
    }

    // destructors
    static _PVFV * pf_atexitlist = 0;
    static unsigned max_atexitlist_entries = 0;
    static unsigned cur_atexitlist_entries = 0;

    void __cdecl _atexit_init(void) {
        max_atexitlist_entries = 32;
        pf_atexitlist = (_PVFV *)talloc(max_atexitlist_entries * sizeof(_PVFV*));
    }
    int __cdecl atexit(_PVFV func ) {
        if ( cur_atexitlist_entries < max_atexitlist_entries ) {
            pf_atexitlist[cur_atexitlist_entries++] = func;
            return 0;
        }
        return -1;
    }
    void __cdecl _DoExit( void ) {
        if ( cur_atexitlist_entries ) {
            _initterm(  pf_atexitlist,
                        // Use ptr math to find the end of the array
                        pf_atexitlist + cur_atexitlist_entries );
        }
    }

    // TOOD: __CxxFrameHandler3, __std_terminate, _C_specific_handler
    //void __cdecl __std_terminate() {}

    // signal() -> FlsAlloc() / TlsAlloc() -> ???


    int WinMain(HINSTANCE app, HINSTANCE prev_app, LPSTR command, int window_options);
    int __stdcall WinMainCRTStartup() {
        qclibInit();
        _atexit_init();
        _initterm((_PVFV*)__xi_a, (_PVFV*)__xi_z);
        _initterm(__xc_a, __xc_z);
        int retCode = WinMain(0, 0, 0, 0);
        _DoExit();
        ExitProcess(retCode);
    }
#endif
