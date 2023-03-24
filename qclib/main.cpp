#include "qclib.h"

int main() {
    initConsole();
    String* str = String::fromC("Hello world\n\0");
    debugPrint(str->data);
    print(str);
    ExitProcess(0);
}
