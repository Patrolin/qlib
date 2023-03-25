#include "qclib.h"

int bar() {
    debugPrint("Bar!");
    return 0;
}
int y = bar();

class Foo {
public:
    Foo() {
        debugPrint("Foo!");
    }
};
static Foo x;

// TODO: GetCommandLineA()?

void panicHandler(int code) {
    debugPrint("Panic: ");
    debugPrintNum(code);
}
inline void segfault() {
    *((volatile char*)0) = 0;
}

#define dll_signal

#ifdef dll_signal
    typedef void (__CRTDECL* _crt_signal_t)(int);
    #define SIGSEGV 11
    typedef _crt_signal_t FSignal(int code, _crt_signal_t f);
    static FSignal* signal = [](int code, _crt_signal_t f) -> _crt_signal_t {
        debugPrint("Called x_signal stub.\n\0");
        return 0;
    };
#else
    #include <signal.h>
#endif


int main() {
    //qclibInit();
    //return 0;
#ifdef dll_signal
    HMODULE msvcrt = LoadLibraryA("msvcrt.dll");
    debugPrintNum((bool) msvcrt);
    debugPrint("\n\0");
    signal = (FSignal*)GetProcAddress(msvcrt, "signal");
    debugPrintNum((uint)signal);

    _crt_signal_t prev_handler = signal(SIGSEGV, panicHandler);
    debugPrint("\nCalled signal()\0");
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
