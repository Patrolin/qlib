from qLib.collections_ import Enum, Flags
from qLib.tests import assert_equals
from . import *
from dataclasses import dataclass

## DOS header

# #include <winnt.h>
# | u16                       | u16                        | u16                      | u16              |
# | magic                     | bytes_on_last_page_in_file | pages_in_file            | relocation_count |
# | header_size_in_paragraphs | minimum_extra_paragraphs   | maximum_extra_paragraphs | initial_ss       |
# | initial_sp                | check_sum                  | initial_ip               | initial_cs       |
# | relocation_table_paddress | overlay_number             | reserved1_[0]            | reserved1_[1]    |
# | reserved1_[2]             | reserved1_[3]              | oem_id                   | oem_info         |
# | reserved2_[0]             | reserved2_[1]              | reserved2_[2]            | reserved2_[3]    |
# | reserved2_[4]             | reserved2_[5]              | reserved2_[6]            | reserved2_[7]    |
# | reserved2_[8]             | reserved2_[9]              | nt_address                                  |
@dataclass
class _DosHeader:
    """Legacy DOS header"""
    magic: u16 # "MZ"
    bytes_on_last_page_in_file: u16
    pages_in_file: u16
    relocation_count: u16
    # 8B
    header_size_in_paragraphs: u16
    minimum_extra_paragraphs: u16
    maximum_extra_paragraphs: u16
    initial_ss: u16
    # 16B
    initial_sp: u16
    check_sum: u16
    initial_ip: u16
    initial_cs: u16
    # 24B
    relocation_table_paddress: u16
    overlay_number: u16
    _reserved1: list[u16] # 4
    oem_id: u16
    oem_info: u16
    # 40B
    _reserved2: list[u16] # 10
    nt_header_address: u32
    # 64B

## NT header
class _PEArch(Enum):
    UNKNOWN = 0
    TARGET_HOST = 0x0001
    I386 = 0x014c
    R3000 = 0x0162
    R4000 = 0x0166
    R10000 = 0x0168
    WCEMIPSV2 = 0x0169
    ALPHA = 0x0184
    SH3 = 0x01a2
    SH3DSP = 0x01a3
    SH3E = 0x01a4
    SH4 = 0x01a6
    SH5 = 0x01a8
    ARM = 0x01c0
    THUMB = 0x01c2
    ARMNT = 0x01c4
    AM33 = 0x01d3
    POWERPC = 0x01F0
    POWERPCFP = 0x01f1
    IA64 = 0x0200
    MIPS16 = 0x0266
    ALPHA64 = 0x0284 # AXP64
    MIPSFPU = 0x0366
    MIPSFPU16 = 0x0466
    TRICORE = 0x0520
    CEF = 0x0CEF
    EBC = 0x0EBC
    AMD64 = 0x8664
    M32R = 0x9041
    ARM64 = 0xAA64
    CEE = 0xC0EE

class _Characteristics(Flags):
    RELOCS_STRIPPED = 0x0001
    EXECUTABLE_IMAGE = 0x0002
    LINE_NUMS_STRIPPED = 0x0004
    LOCAL_SYMS_STRIPPED = 0x0008
    AGGRESIVE_WS_TRIM = 0x0010
    LARGE_ADDRESS_AWARE = 0x0020
    BYTES_REVERSED_LO = 0x0080
    BITS_32 = 0x0100
    DEBUG_STRIPPED = 0x0200
    REMOVABLE_RUN_FROM_SWAP = 0x0400
    NET_RUN_FROM_SWAP = 0x0800
    SYSTEM = 0x1000
    DLL = 0x2000
    UP_SYSTEM_ONLY = 0x4000
    BYTES_REVERSED_HI = 0x8000

## COFF header
# | u16                              | u16                        | u16                      | u16              |
# | architecture                     | sections_count             | time_stamp                                  |
# | _symbols_address                                              | _symbol_count                               |
# | optional_header_size             | characteristics            |
@dataclass
class _CoffHeader: # 20B
    architecture: u16
    sections_count: u16
    time_stamp: u32
    _symbols_address: u32
    _symbol_count: u32
    optional_header_size: u16
    characteristics: u16

    def __repr__(self) -> str:
        return f"CoffHeader(architecture={_PEArch.toString(self.architecture)}, sections_count={self.sections_count}, time_stamp={self.time_stamp}" \
         + f", optional_header_size={self.optional_header_size}, characteristics={_Characteristics.toString(self.characteristics)}"

class _OptionalHeaderMagic(Enum):
    PE32 = 0x10b
    PE64 = 0x20b # PE32+
    #ROM = 0x107?
    #...

class _WindowsSubsystem(Enum):
    UNKNOWN = 0
    NATIVE = 1
    WINDOWS_GUI = 2
    WINDOWS_TERMINAL = 3
    OS2_TERMINAL = 5
    POSIX_TERMINAL = 7
    NATIVE_WIN9x = 8
    WINDOWS_CE_GUI = 9
    EFI_APPLICATION = 10
    EFI_BOOT_SERVICE_DRIVER = 11
    EFI_RUNTIME_DRIVER = 12
    EFI_ROM = 13
    XBOX = 14
    WINDOWS_BOOT_APPLICATION = 16
    XBOX_CODE_CATALOG = 17

class _DllCharacteristics(Flags):
    HIGH_ENTROPY_VA = 0x0020
    DYNAMIC_BASE = 0x0040
    FORCE_INTEGRITY = 0x0080
    NX_COMPAT = 0x0100
    NO_ISOLATION = 0x0200
    NO_SEH = 0x0400
    NO_BIND = 0x0800
    APPCONTAINER = 0x1000
    WDM_DRIVER = 0x2000
    CFG = 0x4000
    TERMINAL_SERVER_AWARE = 0x8000

@dataclass
class _Directory:
    vaddress: u32
    size: u32

class _Directories:
    def __init__(self, directories: list[_Directory]):
        assert_equals(len(directories), 16)
        self.export = directories[0]
        self.import_ = directories[1]
        self.resource = directories[2]
        self.exception = directories[3]
        self.security = directories[4]
        self.base_relocation = directories[5]
        self.debug = directories[6]
        self.architecture_specific = directories[7]
        self.rva_of_gp = directories[8]
        self.thread_local = directories[9]
        self.load_config = directories[10]
        self.bound_import = directories[11]
        self.iat = directories[12]
        self.delay_load = directories[13]
        self.com_runtime = directories[14]
        self._reserved = directories[15]

    def __repr__(self) -> str:
        return "Directories(" + ", ".join(f"{k}={repr(self.__dict__[k])}" for k in [
            "export", "import_", "resource", "exception", "security", "base_relocation", "debug", "architecture_specific", "rva_of_gp",
            "thread_local", "load_config", "bound_import", "iat", "delay_load", "com_runtime", "_reserved"
        ] if (self.__dict__[k].vaddress != 0) or (self.__dict__[k].size != 0)) + ")"

## Optional header (only for images)
# | u16                              | u16                                         | u16                         | u16                         |
# | magic                            | major_linker_version | minor_linker_version | codeSize                                                  |
# | initialized_data_size                                                          | uninitialized_data_size                                   |
# | entry_point_address                                                            | code_address                                              |
# | image_base                                                                                                                                 |
# | section_alignment                                                              | file_alignment                                            |
# | major_operating_system_version   | minor_operating_system_version              | major_image_version         | minor_image_version         |
# | major_subsystem_version          | minor_subsystem_version                     | _reserved1                                                |
# | image_size                                                                     | headers_size                                              |
# | check_sum                                                                      | subsystem                   | dll_characteristics         |
# | stack_reserve_size                                                                                                                         |
# | stack_commit_size                                                                                                                          |
# | heap_reserve_size                                                                                                                          |
# | heap_commit_size                                                                                                                           |
# | _reserved2                                                                     | rva_count_and_sizes                                       |
# + u32 _data_address if PE32
# + IMAGE_DATA_DIRECTORY[16]
@dataclass
class _OptionalHeader:
    magic: u16
    linker_version: list[u8]
    codeSize: u32
    initialized_data_size: u32
    uninitialized_data_size: u32
    entry_point_address: u32
    code_address: u32
    image_base: u64
    section_alignment: u32
    file_alignment: u32
    operating_system_version: list[u16]
    image_version: list[u16]
    subsystem_version: list[u16]
    _reserved1: u32
    image_size: u32
    headers_size: u32
    check_sum: u32
    subsystem: u16
    dll_characteristics: u16
    stack_reserve_size: u64
    stack_commit_size: u64
    heap_reserve_size: u64
    heap_commit_size: u64
    _reserved2: u32
    rva_count_and_sizes: u32
    _data_address: u32
    directories: _Directories

    def __repr__(self) -> str:
        return f"OptionalHeader(magic={_OptionalHeaderMagic.toString(self.magic)}, linker_version={self.linker_version}, codeSize={self.codeSize}" \
         + f", initialized_data_size={self.initialized_data_size}, uninitialized_data_size={self.uninitialized_data_size}" \
         + f", entry_point_address=0x{self.entry_point_address:x}, code_address=0x{self.code_address:x}, image_base=0x{self.image_base:x}" \
         + f", section_alignment={self.section_alignment}, file_alignment={self.file_alignment}, operating_system_version={self.operating_system_version}" \
         + f", image_version={self.image_version}, subsystem_version={self.subsystem_version}, _reserved1={self._reserved1}, image_size={self.image_size}" \
         + f", headers_size={self.headers_size}, check_sum=0x{self.check_sum:x}, subsystem={_WindowsSubsystem.toString(self.subsystem)}" \
         + f", dll_characteristics={_DllCharacteristics.toString(self.dll_characteristics)}, stack_reserve_size={self.stack_reserve_size}" \
         + f", stack_commit_size={self.stack_commit_size}, heap_reserve_size={self.heap_reserve_size}, heap_commit_size={self.heap_commit_size}" \
         + f", _reserved2={self._reserved2}, rva_count_and_sizes={self.rva_count_and_sizes}, directories={self.directories}"

@dataclass
class _NTHeader:
    magic: u32 # "PE\0\0"
    coff_header: _CoffHeader
    optional_header: _OptionalHeader

## Section headers
class _SectionCharacteristics(Flags):
    HAS_CODE = 0x00000020
    HAS_INITIALIZED_DATA = 0x00000040
    HAS_UNINITIALIZED_DATA = 0x00000080
    HAS_INFO = 0x00000200
    HAS_NOTHING = 0x00000800
    HAS_COMDAT = 0x00001000
    NO_DEFER_SPEC_EXC = 0x00004000
    GPREL = 0x00008000
    MEM_FARDATA = 0x00008000
    MEM_PURGEABLE = 0x00020000
    MEM_16BIT = 0x00020000
    MEM_LOCKED = 0x00040000
    MEM_PRELOAD = 0x00080000
    ALIGN_1BYTES = 0x00100000
    ALIGN_2BYTES = 0x00200000
    ALIGN_4BYTES = 0x00300000
    ALIGN_8BYTES = 0x00400000
    ALIGN_16BYTES = 0x00500000
    ALIGN_32BYTES = 0x00600000
    ALIGN_64BYTES = 0x00700000
    ALIGN_128BYTES = 0x00800000
    ALIGN_256BYTES = 0x00900000
    ALIGN_512BYTES = 0x00A00000
    ALIGN_1024BYTES = 0x00B00000
    ALIGN_2048BYTES = 0x00C00000
    ALIGN_4096BYTES = 0x00D00000
    ALIGN_8192BYTES = 0x00E00000
    LNK_NRELOC_OVFL = 0x01000000
    MEM_DISCARDABLE = 0x02000000
    MEM_NOT_CACHED = 0x04000000
    MEM_NOT_PAGED = 0x08000000
    MEM_SHARED = 0x10000000
    MEM_EXECUTE = 0x20000000
    MEM_READ = 0x40000000
    MEM_WRITE = 0x80000000

## section header
# | u16                       | u16                        | u16                      | u16              |
# | name                                                                                                 |
# | vsize                                                  | vaddress                                    |
# | psize                                                  | paddress                                    |
# | _relocations_address                                   | _line_numbers_address                       |
# | _relocations_count        | _line_numbers_count        | sectionCharacteristics                      |
@dataclass
class _SectionHeader: # 40B
    # .text = bytecode
    # .CRT = C Run Time
    name: str
    vsize: u32
    vaddress: u32
    psize: u32
    paddress: u32
    _relocations_address: u32
    _line_numbers_address: u32
    _relocations_count: u16
    _line_numbers_count: u16
    section_characteristics: u32

    def __repr__(self) -> str:
        return f"SectionHeader(name={self.name}, vsize={self.vsize}, vaddress={self.vaddress}" \
            + f", psize={self.psize}, paddress={self.paddress}, section_characteristics={_SectionCharacteristics.toString(self.section_characteristics)}"

@dataclass
class _PE:
    dos: _DosHeader
    nt: _NTHeader

def parse_pe(string: str) -> _PE:
    ... # TODO
