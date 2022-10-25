# TODO: rename to parsing
from typing import NewType

DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

u8 = NewType("u8", int) # BYTE
u16 = NewType("u16", int) # WORD
u32 = NewType("u32", int) # DWORD = LONG
u64 = NewType("u64", int) # QWORD = ULONGLONG

from .serialize_float import *
from .serialize_int import *
from .serialize_string import *
