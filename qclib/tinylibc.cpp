#include <windows.h>
#pragma comment(linker, "/defaultlib:user32.lib")
#pragma comment(linker, "/defaultlib:kernel32.lib")
#include <stdint.h>
#pragma comment(linker, "/nodefaultlib:libc.lib")
#pragma comment(linker, "/nodefaultlib:libcmt.lib")

// print
typedef uint64_t uint;
uint cstrCount(const char* start) {
    const char* end = start;
    while (*end != 0) { end++; };
    return end - start;
}
void print(const char* message) {
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), message, cstrCount(message), 0, 0);
}

// initterm
typedef void (__cdecl* _PVFV)(void);
#pragma section(".CRT$XCA", long, read)
#pragma section(".CRT$XCZ", long, read)
__declspec(allocate(".CRT$XCA")) _PVFV __xc_a[] = { NULL };
__declspec(allocate(".CRT$XCZ")) _PVFV __xc_z[] = { NULL };
//__declspec(allocate(".CRT$XPA")) _PVFV __xp_a[] = { NULL };
//__declspec(allocate(".CRT$XPZ")) _PVFV __xp_z[] = { NULL };
#pragma comment(linker, "/merge:.CRT=.rdata")

void __cdecl _initterm (_PVFV * pfbegin, _PVFV * pfend) {
    while ( pfbegin < pfend ) {
        // if current table entry is non-NULL, call it
        if ( *pfbegin != NULL )
            (**pfbegin)();
        ++pfbegin;
    }
}
/*
static _PVFV * pf_atexitlist = 0;
static unsigned max_atexitlist_entries = 0;
static unsigned cur_atexitlist_entries = 0;
void __cdecl _atexit_init(void) {
    max_atexitlist_entries = 32;
    pf_atexitlist = (_PVFV *)calloc( max_atexitlist_entries,
                                     sizeof(_PVFV*) );
}
int __cdecl atexit (_PVFV func ) {
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
}*/

// dllcrto
/*
extern BOOL WINAPI DllMain(HANDLE hDllHandle, DWORD dwReason, LPVOID lpreserved);
//
// Modified version of the Visual C++ startup code.  Simplified to
// make it easier to read.  Only supports ANSI programs.
//
extern "C"
BOOL WINAPI _DllMainCRTStartup(HANDLE hDllHandle, DWORD dwReason, LPVOID lpreserved) {
    if ( dwReason == DLL_PROCESS_ATTACH ) {
        // set up our minimal cheezy atexit table
        //_atexit_init();

        // Call C++ constructors
        _initterm( __xc_a, __xc_z );
    }
    BOOL retcode = DllMain(hDllHandle, dwReason, lpreserved);
    if ( dwReason == DLL_PROCESS_DETACH ) {
        //_DoExit();
    }
    return retcode ;
}*/
// maincrto
int main( int argc, char *argv[] );
int mainCRTStartup() {
    //_atexit_init();
    _initterm( __xc_a, __xc_z );
    BOOL retcode = main(0, 0);
    //_DoExit();
    return retcode ;
}

/*
void panicHandler(int code) {
    print("Panic!");
}
inline void segfault() {
    *((volatile char*)0) = 0;
}
*/
int main(int argc, char *argv[]) {
    print("hello world\0");
    //signal(SIGSEGV, panicHandler);
    //segfault();
}
