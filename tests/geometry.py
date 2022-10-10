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
    print("A&B")
    PGA_2D.print_table(lambda a, b: a & b)
    print("A|B")
    PGA_2D.print_table(lambda a, b: a | b)
    if True:
        print("A commutator B")
        PGA_2D.print_table(lambda a, b: a.commutator(b))
        print("-(A.dual() commutator B).undual()")
        PGA_2D.print_table(lambda a, b: -a.dual().commutator(b).undual())
    if False:
        for G in (PGA_3D, CGA_2D):
            G.print_name()
            G.print_row(lambda v: v)
            print("~A")
            G.print_row(lambda v: ~v)
            print("A.dual()")
            G.print_row(lambda v: v.dual())
            print("A.undual()")
            G.print_row(lambda v: v.undual())

if __name__ == "__main__":
    run_tests()
