// 14 KB hello world
#include <windows.h>
#include <stdint.h>

// int
typedef unsigned int uint;
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
HANDLE stdout = 0;
void initConsole() {
    AllocConsole();
    stdout = GetStdHandle(-11);
}
uint cstrCount(const char* start) {
    const char* end = start;
    while (*end != 0) { end++; };
    return end - start;
}
void debugPrint(const char* cstr) {
    WriteConsoleA(stdout, cstr, cstrCount(cstr), 0, 0);
}
const uint U64_MAX_BASE10_DIGITS = 20;
void debugPrintNum(uint number) {
    char format[U64_MAX_BASE10_DIGITS+1];
    char* curr = format + U64_MAX_BASE10_DIGITS+1;
    *--curr = 0;
    while (number > 0) {
        *--curr = '0' + (number % 10);
        number /= 10;
    }
    WriteConsoleA(stdout, curr, U64_MAX_BASE10_DIGITS-(curr-format), 0, 0);
}
struct String {
    uint count;
    char* data;
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

struct SimpleAlloc {
    u8* start = 0;
    uint size = 0;
    uint data_size = 0;
};
SimpleAlloc _simple_alloc = {};
void* alloc(uint size) {
    uint new_data_size = _simple_alloc.data_size + size;
    if (new_data_size > _simple_alloc.size) {
        uint new_size = _simple_alloc.size + kiloBytes(1);
        _simple_alloc.start = (u8*)VirtualAlloc(_simple_alloc.start, new_size, MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE);
        if (_simple_alloc.start == 0) {
            debugPrint("AllocError");
            Sleep(1000);
            ExitProcess(1);
        }
        _simple_alloc.size = new_size;
    }
    void* data = _simple_alloc.start + _simple_alloc.data_size;
    _simple_alloc.data_size = new_data_size;
    return data;
}
