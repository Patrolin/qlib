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

// TODO: fork C:\Program Files (x86)\Windows Kits\10\Source\10.0.19041.0\ucrt\misc\signal.h
