from .datetime import *
from .math_ import *
from .geometry import *
from .qoi import *
from .statistics import *
from .tests import *
from .vtcodes import *
from .collections_ import *
from .serialize import *

def relative_path(prefix: str, suffix: str) -> str:
    BACKSLASH = "\\"
    return prefix.replace(BACKSLASH, "/").rsplit("/", 1)[0] + suffix
