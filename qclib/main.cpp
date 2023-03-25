#include "qclib.h"
#if 1
    #include <signal.h>
#else
    typedef void (__cdecl* _crt_signal_t)(int);
    #define SIGSEGV 11
#endif

//void (*signal(int, void (*)(int)))(int);
//void __cdecl *signal(int sig, int (*func)(int, int));

void panicHandler(int code) {
    debugPrint("Panic: ");
    debugPrintNum(code);
}
inline void segfault() {
    *((volatile char*)0) = 0;
}


#define X_SIGNAL(name) _crt_signal_t name(int code, _crt_signal_t f)
typedef X_SIGNAL(x_signal);
X_SIGNAL(x_signal_stub) {
    debugPrint("Called x_signal stub.\n\0");
    return 0;
}
static x_signal* xSignal_ = x_signal_stub;
#define xSignal xSignal_


int main() {
    qclibInit();
    //return 0;
#if 1
    HMODULE msvcrt = LoadLibraryA("msvcrt.dll");
    debugPrintNum((bool) msvcrt);
    debugPrint("\n\0");
    xSignal = (x_signal*)GetProcAddress(msvcrt, "signal");
    debugPrintNum((uint)xSignal);

    _crt_signal_t prev_handler = xSignal(SIGSEGV, panicHandler);
    debugPrint("\nCalled xSignal()\0");
    debugPrintNum((uint) prev_handler);
#else
    signal(SIGSEGV, panicHandler);
#endif
    segfault();

    String* str = String::fromC("Hello world\n\0");
    debugPrint(str->data);
    print(str);
    ExitProcess(0);
}
int WinMain(HINSTANCE app, HINSTANCE prev_app, LPSTR command, int window_options) {
    main();
}
