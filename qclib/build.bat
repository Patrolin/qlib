@echo off
clang .\qclib\main.cpp -o .\qclib\out\qclib.exe -nostdlib -nostdlib++ -no-integrated-cpp -z /subsystem:windows -z /entry:main -z Kernel32.lib -z User32.lib -g -gcodeview
