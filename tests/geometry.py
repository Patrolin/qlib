from qLib.tests import test, run_tests
from qLib.geometry import *

#@test
def testPGA_2D():
    PGA_2D.print_name()
    print("~A")
    PGA_2D.print_row(lambda v: ~v) # TODO print to string
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

@test
def testWedge():
    for G in (PGA_2D, PGA_3D, PGA_4D, CGA_2D, CGA_3D):
        G.assert_equals(lambda a, b: a & b, lambda a, b: (a.dual() ^ b.dual()).undual())
        G.assert_equals(lambda a, b: a ^ b, lambda a, b: (a.dual() & b.dual()).undual())

@test
def testMultivector():
    for G in (PGA_2D, PGA_3D):
        #G.print_name()
        A = point2D(1, 2)
        B = point2D(2, 3)
        assert_equals(repr(A), "(1e0 + 1e1 + 2e2)")
        assert_equals(repr(B), "(1e0 + 2e1 + 3e2)")
        assert_equals(repr(A * B), "(1e01 - 1e20 + 8 - 1e12)")
        assert_equals((A * B).dnorm(), 1.4142135623730951)
        assert_equals((A * B).pnorm(), 8.06225774829855)
        assert_equals(repr((A * B).inverse()),
                      "(-0.015384615384615387e01 + 0.015384615384615387e20 + 0.1230769230769231 + 0.015384615384615387e12)")

if __name__ == "__main__":
    run_tests()
