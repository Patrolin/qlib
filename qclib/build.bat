@echo off
:: 14336 B
::clang .\qclib\main.cpp -o .\qclib\out\qclib.exe -nostdlib -z /subsystem:windows -z /entry:main -nostdlib++ -no-integrated-cpp -z Kernel32.lib -z User32.lib -g -gcodeview
:: <signal.h> depends on stdlib
:: TODO: fork signal.h so that it doesn't depend on stdlib

:: With these removed: -nostdlib -z /subsystem:windows -z /entry:main
:: 567808 B
clang .\qclib\main.cpp -o .\qclib\out\qclib.exe -nostdlib++ -no-integrated-cpp -z /subsystem:windows -z Kernel32.lib -z User32.lib -g -gcodeview

:: TODO: libctiny.lib?
:: TODO: check .MAP file to find space optimizations
