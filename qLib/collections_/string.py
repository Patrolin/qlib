__all__ = ["normalize", "string_similarity"]
from qLib.math_ import log
import unicodedata

def normalize(string: str, case_sensitive = False, accent_sensitive = False, symbol_sensitive = False) -> str:
    acc = unicodedata.normalize("NFD", string) if symbol_sensitive else unicodedata.normalize("NFKD", string)
    acc = acc if accent_sensitive else "".join(v for v in acc if not unicodedata.combining(v))
    acc = acc if case_sensitive else acc.lower()
    return acc

def string_similarity(filter: str, option: str) -> float:
    '''return a string similarity between filter and option in O(len(filter) + len(option))'''
    length_sum = len(filter) + len(option)
    if length_sum == 0: return 1.0

    counts = dict()
    for char in filter:
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
