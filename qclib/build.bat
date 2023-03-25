@echo off
set my_files=.\qclib\main.cpp -o .\qclib\out\qclib.exe
set my_args=-nostdlib++ -no-integrated-cpp -z /subsystem:windows -z Kernel32.lib -z User32.lib -g -gcodeview -z -Map:.\qclib\out\qclib.map

::clang %my_files% %my_args% -nostdlib -z /entry:main
:: 14336 B
:: but <signal.h> depends on stdlib
:: we want a fork of <signal.h> that doesn't depend on stdlib
:: except Microsoft does not support this anymore, the closest we have is a chinese reverse engineer of <ucrt/corecrt_internal.h>

::clang %my_files% %my_args%
:: 567808 B

clang %my_files% %my_args% -nostdlib -z msvcrt.lib
:: 40448 B

:: TODO: make custom CRTStartup like in libctiny.lib
:: https://learn.microsoft.com/en-us/cpp/c-runtime-library/crt-library-features?view=msvc-170
:: (and check linker .MAP file to find even more space optimizations)
