@echo off
set my_files=.\qclib\main.cpp -o .\qclib\out\qclib.exe
set my_args=-nostdlib++ -no-integrated-cpp -z /subsystem:windows -g -gcodeview -DNO_STDLIB

clang %my_files% %my_args% -nostdlib -z ucrt.lib -z -Map:.\qclib\out\qclib-nostdlib.map
:: 14336 B
:: but <signal.h> depends on stdlib
:: we want a fork of <signal.h> that doesn't depend on stdlib
:: except Microsoft does not support this anymore, the closest we have is a chinese reverse engineer of <ucrt/corecrt_internal.h>

:: TODO: -GS- -Gs9999999 -stack:0x100000,0x100000 to avoid bs traps
:: TODO: -fno-exceptions ?

::clang %my_files% %my_args% -z -Map:.\qclib\out\qclib-fullstdlib.map
:: 567808 B

::clang %my_files% %my_args% -nostdlib -z msvcrt.lib -z -Map:.\qclib\out\qclib-msvcrt.map
:: 40448 B
