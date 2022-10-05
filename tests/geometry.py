from typing import Iterable
from qLib.tests import test, run_tests
from qLib.geometry import *
from qLib.geometry2 import *

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
    print("A.right_complement()")
    print_row(v.right_complement() for v in PGA_2D.blades)
    print("A*B")
    for a in PGA_2D.blades:
        print_row(a * b for b in PGA_2D.blades)
    print("A inner B")
    for a in PGA_2D.blades:
        print_row(a.inner(b) for b in PGA_2D.blades)
    print("A&B")
    for a in PGA_2D.blades:
        print_row(a & b for b in PGA_2D.blades)
    print("A|B")
    for a in PGA_2D.blades:
        print_row(a | b for b in PGA_2D.blades)
    if True:
        print("A commutator B")
        for a in PGA_2D.blades:
            print_row(a.commutator(b) for b in PGA_2D.blades)
        # M = -0.5*M*B ?
        # B = -(A.dual() commutator B).undual()
        print("-(A.dual() commutator B).undual()") # -m[3]m[4]e01 + m[2]m[4]e20 ?????
        for a in PGA_2D.blades:
            print_row(-a.dual().commutator(b).undual() for b in PGA_2D.blades)
    if False:
        for G in (VGA_2D, VGA_3D, PGA_2D):
            print("A.dual()")
            print_row(v.dual() for v in G.blades)
            print("A.undual()")
            print_row(v.undual() for v in G.blades)
            print("A^!A")
            print_row(v * v.dual() for v in G.blades)
    print("A.dual()")
    print_row(v.dual() for v in VGA_2D.blades)
    print("A.right_complement()")
    print_row(v.right_complement() for v in VGA_2D.blades)
    print("A.dual()")
    print_row(v.dual() for v in VGA_3D.blades)
    print("A.right_complement()")
    print_row(v.right_complement() for v in VGA_3D.blades)
    print("A.dual()")
    print_row(v.dual() for v in CGA_2D.blades)
    print("A.right_complement()")
    print_row(v.right_complement() for v in CGA_2D.blades)
    print("A.dual()")
    print_row(v.dual() for v in PGA_3D.blades)
    if False:
        print("A.right_complement()")
        print_row(v.right_complement() for v in PGA_3D.blades)
    print("A...")
    print(PGA2D_.blades)
    print_row(v.right_complement() for v in PGA2D_.blades)
    print_row(v.left_complement() for v in PGA2D_.blades)

if __name__ == "__main__":
    run_tests()
