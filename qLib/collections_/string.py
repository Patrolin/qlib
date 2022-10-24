__all__ = ["normalize", "string_similarity"]
from qLib.math_ import log
import unicodedata

from qLib.tests import assert_between

def normalize(string: str, case_sensitive = False, accent_sensitive = False, symbol_sensitive = False) -> str:
    acc = unicodedata.normalize("NFD", string) if symbol_sensitive else unicodedata.normalize("NFKD", string)
    acc = acc if accent_sensitive else "".join(v for v in acc if not unicodedata.combining(v))
    acc = acc if case_sensitive else acc.lower()
    return acc

def string_similarity(value: str, option: str) -> float:
    '''return a string similarity between value and option in O(len(value) + len(option))'''
    length_sum = len(value) + len(option)
    if length_sum == 0: return 1.0

    counts = dict()
    for char in value:
        counts[char] = counts[char] + 1 if (char in counts) else 1
    matches, bad_mismatches, okay_mismatches = 0, 0, 0
    for char in option:
        if (char in counts):
            if (counts[char] > 0):
                counts[char] -= 1
                matches += 1
            else:
                okay_mismatches += 1
        else:
            bad_mismatches += 1
    for count in counts.values():
        bad_mismatches += count

    if (bad_mismatches + okay_mismatches) == 0: return 1.0
    return (2 * matches / length_sum) / log(1 + bad_mismatches + okay_mismatches / 2)

# other options:
# https://handwiki.org/wiki/Gestalt_Pattern_Matching
# https://handwiki.org/wiki/Damerau–Levenshtein_distance

class DiffToken:
    def __init__(self, type: int, value: str, index: int):
        assert_between(type, 0, 1)
        self.type = type
        self.value = value
        self.index = index

    def __repr__(self):
        return f"{'-+'[self.type]}{self.value}@{self.index}"

def diff(a: str, b: str) -> list[DiffToken]: # TODO: tests
    '''return a diff between a and b in O(len(a) + len(b))'''
    acc: list[DiffToken] = []
    LOOKAHEAD = 5
    i = 0
    j = 0
    while i < len(a) and j < len(b):
        if a[i] == b[j]:
            i += 1
            j += 1
        else:
            k = 0
            while True:
                k += 1
                if a[i + k:i + k + LOOKAHEAD] == b[j:j + LOOKAHEAD]: # TODO: optimize this
                    acc.append(DiffToken(0, a[i:i + k], i))
                    i += k
                    break
                elif b[j + k:j + k + LOOKAHEAD] == a[i:i + LOOKAHEAD]:
                    acc.append(DiffToken(1, b[j:j + k], j))
                    j += k
                    break
    if i < len(a): acc.append(DiffToken(0, a[i:], i))
    if j < len(b): acc.append(DiffToken(1, b[j:], j))
    return acc
