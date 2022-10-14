from .math_ import *
from .geometry import *
from .quiteok import *
from .statistics import *
from .tests import *
from .time_ import *
from .vtcodes import *

from .collections_ import *
from .serialize import *

def relative_path(prefix: str, suffix: str) -> str: # TODO: move this somewhere
    BACKSLASH = "\\"
    return prefix.replace(BACKSLASH, "/").rsplit("/", 1)[0] + suffix
