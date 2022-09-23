from typing import Iterable
from qLib.tests import test, run_tests
from qLib.geometry import *

def print_row(arr: Iterable):
    print("".join(str(v).rjust(9, " ") for v in arr))

@test
def testPGA_2D():
    #print(PGA_2D.parse_blade("-22e1", 0)[1] * PGA_2D.parse_blade("4", 0)[1])
    print("~A")
    print_row(~v for v in PGA_2D.blades)
    print("A.involute()")
    print_row(v.involute() for v in PGA_2D.blades)
    print("A.conjugate()")
    print_row(v.conjugate() for v in PGA_2D.blades)
    print("A.dual()")
    print_row(v.dual() for v in PGA_2D.blades)
    print("A*B")
    for a in PGA_2D.blades:
        print_row(a * b for b in PGA_2D.blades)
    print("A inner B")
    for a in PGA_2D.blades:
        print_row(a.inner(b) for b in PGA_2D.blades)
    print("A^B")
    for a in PGA_2D.blades:
        print_row(a ^ b for b in PGA_2D.blades)
    if True:
        print("A.dual()")
        print_row(v.dual() for v in VGA_3D.blades)
        print("A.undual()")
        print_row(v.undual() for v in VGA_3D.blades)
        print("A.dual()")
        print_row(v.dual() for v in VGA_2D.blades)
        print("A.undual()")
        print_row(v.undual() for v in VGA_2D.blades)
        print("A inner B")
        for a in VGA_2D.blades:
            print_row([(a.inner(b)) for b in VGA_2D.blades])
        #print("(A & B.dual()).undual()")
        #for a in VGA_2D.blades:
        #    print_row([(a & b.dual()).undual() for b in VGA_2D.blades])
        print("A & B")
        for a in VGA_2D.blades:
            print_row([(a & b) for b in VGA_2D.blades])
        #print("(A inner B.dual()).undual()")
        #for a in VGA_2D.blades:
        #    print_row([(a.inner(b.dual())).undual() for b in VGA_2D.blades])
    print("A&B")
    for a in PGA_2D.blades:
        print_row(a & b for b in PGA_2D.blades)
    print("A|B")
    for a in PGA_2D.blades:
        print_row(a | b for b in PGA_2D.blades)

if __name__ == "__main__":
    run_tests()
