// we want: #define BITS_64 (sizeof(void*) == 8)
// but C++ is stupid and doesn't allow sizeof(), constexpr or defined() in preprocessor

// bits
#if (defined(_WIN64) || defined(__x86_64__))
    #define BITS_64 1
#elif defined(__i386__)
    #define BITS_32 1
#else
    static_assert(false, "Unknown BITS_xx")
#endif

// arch
#if (defined(__x86_64__) || defined(__x86__))
    #define ARCH_X86 1
#else
    static_assert(false, "Unknown ARCH_xx")
#endif

// os
#if (defined(_WIN32) || defined(_WIN64))
    #define OS_WIN 1
#elif defined(__unix__)
    #define OS_UNIX 1
#elif (defined(__APPLE__) || defined(__MACH__))
    #define OS_APPLE 1
#else
    static_assert(false, "Unknown OS_xx")
#endif
