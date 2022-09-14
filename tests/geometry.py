from qLib.tests import test, run_tests
from qLib.geometry import *

@test
def testPGA_2D():
    PGA_2D = GAlgebra([ \
        ["1",   "e0",  "e1",  "e01"],
        ["e0",  "0",   "e01", "0"],
        ["e1",  "-e01","1",   "-e0"],
        ["e01", "0",   "e0",  "0"],
    ])
    print(PGA_2D.parse_blade("-22e0", 0)[1] + PGA_2D.parse_blade("4e0", 0)[1])
    print(PGA_2D.parse_blade("-22e1", 0)[1] * PGA_2D.parse_blade("4e0", 0)[1])

if __name__ == "__main__":
    run_tests()
