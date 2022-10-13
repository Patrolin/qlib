from qLib.tests import test, run_tests
from qLib.geometry import *

@test
def testPGA_2D():
    PGA_2D.print_name()
    print("~A")
    PGA_2D.print_row(lambda v: ~v)
    print("A.dual()")
    PGA_2D.print_row(lambda v: v.dual())
    print("A.undual()")
    PGA_2D.print_row(lambda v: v.undual())
    print("A*B")
    PGA_2D.print_table(lambda a, b: a * b)
    print("A^B")
    PGA_2D.print_table(lambda a, b: a ^ b)
    print("A&B")
    PGA_2D.print_table(lambda a, b: a & b)
    if True:
        print("A commutator B")
        PGA_2D.print_table(lambda a, b: a.commutator(b))
        print("-(A.dual() commutator B).undual()")
        PGA_2D.print_table(lambda a, b: -a.dual().commutator(b).undual())

#@test
def testWedge():
    for G in (PGA_2D, PGA_3D, PGA_4D, CGA_2D, CGA_3D):
        G.assert_equals(lambda a, b: a & b, lambda a, b: (a.dual() ^ b.dual()).undual())
        G.assert_equals(lambda a, b: a ^ b, lambda a, b: (a.dual() & b.dual()).undual())

@test
def testMultivector():
    for G in (PGA_2D, PGA_3D):
        G.print_name()
        A = G.parse_multivector("1+2e1+e012")[0]
        B = G.parse_multivector("1+e1")[0]
        print(A)
        print(B)
        print(A * B)

if __name__ == "__main__":
    run_tests()
