// 14 KB hello world
//#define USE_NOLIBS // TODO
#include <windows.h>
#pragma comment(linker, "/defaultlib:user32.lib")
#pragma comment(linker, "/defaultlib:kernel32.lib")
#include <stdint.h>
#pragma comment(linker, "/nodefaultlib:libcmt.lib")
#pragma comment(linker, "/nodefaultlib:msvcmrt.lib")
//#pragma comment(linker, "/nodefaultlib:msvcrt.lib")

// int
typedef int64_t sint;
typedef uint64_t uint;
typedef uint32_t bool32;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;

void* alloc(uint size);

// print
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
        String* str = (String*)alloc(sizeof(String));
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
void* alloc(uint size) {
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
#ifdef NO_STDLIB
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

    int WinMain(HINSTANCE app, HINSTANCE prev_app, LPSTR command, int window_options);
    int __stdcall WinMainCRTStartup() {
        qclibInit();
        _initterm((_PVFV*)__xi_a, (_PVFV*)__xi_z);
        _initterm(__xc_a, __xc_z);
        int retCode = WinMain(0, 0, 0, 0);
        ExitProcess(retCode);
    }
#endif
