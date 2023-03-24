namespace __crt_state_management {
    template <typename T>
    struct dual_state_global {
        T data;
        void initialize(T value) {
            this->data = value;
        }
        T value() {
            return this->data;
        }
    };
}

#ifdef _DEBUG
    #define _malloc_crt malloc
#else
    #define _malloc_crt(s) (_malloc_dbg(s, _CRT_BLOCK, __FILE__, __LINE__))
#endif

// TODO: copy ucrt/signal.h
