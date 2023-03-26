// bits
constexpr bool BITS_32 (sizeof(short) == sizeof(int));
#define BITS_64 !BITS_32

// arch
#define ARCH_X86 (defined(__x86_64__) || defined(__x86__))

// os
#define OS_WIN (defined(_WIN32) || defined(WIN32) || defined(_WIN64))
#define OS_UNIX defined(__unix__)
#define OS_APPLE (defined(__APPLE__) || defined(__MACH__))
