from qLib.tests import test, run_tests
from qLib.geometry import *

@test
def testPGA_2D():
    print(PGA_2D.parse_blade("-22", 0)[1] + PGA_2D.parse_blade("4", 0)[1])
    print(PGA_2D.parse_blade("-22e1", 0)[1] * PGA_2D.parse_blade("4", 0)[1])

if __name__ == "__main__":
    run_tests()
