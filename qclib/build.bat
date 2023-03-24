@echo off
::clang .\qclib\main.cpp -o .\qclib\out\qclib.exe -nostdlib -z /subsystem:windows -z /entry:main -nostdlib++ -no-integrated-cpp -z Kernel32.lib -z User32.lib -g -gcodeview
:: -nostdlib -z /subsystem:windows -z /entry:main :: these prevent you from using <signal.h>
clang .\qclib\main.cpp -o .\qclib\out\qclib.exe -nostdlib++ -no-integrated-cpp -z /subsystem:windows -z Kernel32.lib -z User32.lib -g -gcodeview
:: TODO: libctiny.dll?
:: TODO: check .MAP file to find space optimizations
