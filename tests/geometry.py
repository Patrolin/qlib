from qLib.tests import test, run_tests
from qLib.geometry import *

@test
def testPGA_2D():
    #PGA_2D.print_name()
    assert_equals(PGA_2D.tprint_row(lambda v: ~v), "        1       e0       e1       e2     -e01     -e20     -e12    -e012")
    assert_equals(PGA_2D.tprint_row(lambda v: v.dual()), "     e012      e12      e20      e01       e2       e1       e0        1")
    assert_equals(PGA_2D.tprint_row(lambda v: v.undual()), "     e012      e12      e20      e01       e2       e1       e0        1")
    assert_equals(
        PGA_2D.tprint_table(lambda a, b: a * b), """        1       e0       e1       e2      e01      e20      e12     e012
       e0        0      e01     -e20        0        0     e012        0
       e1     -e01        1      e12      -e0     e012       e2      e20
       e2      e20     -e12        1     e012       e0      -e1      e01
      e01        0       e0     e012        0        0     -e20        0
      e20        0     e012      -e0        0        0      e01        0
      e12     e012      -e2       e1      e20     -e01       -1      -e0
     e012        0      e20      e01        0        0      -e0        0""")
    assert_equals(
        PGA_2D.tprint_table(lambda a, b: a ^ b), """        1       e0       e1       e2      e01      e20      e12     e012
       e0        0      e01     -e20        0        0     e012        0
       e1     -e01        0      e12        0     e012        0        0
       e2      e20     -e12        0     e012        0        0        0
      e01        0        0     e012        0        0        0        0
      e20        0     e012        0        0        0        0        0
      e12     e012        0        0        0        0        0        0
     e012        0        0        0        0        0        0        0""")
    assert_equals(
        PGA_2D.tprint_table(lambda a, b: a & b), """        0        0        0        0        0        0        0        1
        0        0        0        0        0        0        1       e0
        0        0        0        0        0        1        0       e1
        0        0        0        0        1        0        0       e2
        0        0        0        1        0      -e0       e1      e01
        0        0        1        0       e0        0      -e2      e20
        0        1        0        0      -e1       e2        0      e12
        1       e0       e1       e2      e01      e20      e12     e012""")
    if True:
        assert_equals(
            PGA_2D.tprint_table(lambda a, b: a.commutator(b)), """        0        0        0        0        0        0        0        0
        0        0      e01     -e20        0        0        0        0
        0     -e01        0      e12      -e0        0       e2        0
        0      e20     -e12        0        0       e0      -e1        0
        0        0       e0        0        0        0     -e20        0
        0        0        0      -e0        0        0      e01        0
        0        0      -e2       e1      e20     -e01        0        0
        0        0        0        0        0        0        0        0""")
        assert_equals(
            PGA_2D.tprint_table(lambda a, b: -a.dual().commutator(b).undual()),
            """        0        0        0        0        0        0        0        0
        0        0      e01     -e20      -e1       e2        0        0
        0        0        0      e12        0        0      -e2        0
        0        0     -e12        0        0        0       e1        0
        0      -e1       e0        0        0     -e12      e20        0
        0       e2        0      -e0      e12        0     -e01        0
        0        0      -e2       e1        0        0        0        0
        0        0        0        0        0        0        0        0""")

@test
def testWedge():
    for G in (PGA_2D, PGA_3D, PGA_4D, CGA_2D, CGA_3D):
        G.assert_equals(lambda a, b: a & b, lambda a, b: (a.dual() ^ b.dual()).undual())
        G.assert_equals(lambda a, b: a ^ b, lambda a, b: (a.dual() & b.dual()).undual())

@test
def testMultivector():
    A = point2D(1, 2)
    B = point2D(2, 3)
    assert_equals(repr(A), "(e0 + e1 + 2e2)")
    assert_equals(repr(B), "(e0 + 2e1 + 3e2)")
    assert_equals(repr(A * B), "(8 + e01 - e20 - e12)")
    assert_equals(repr((A * B).dnorm()), "sqrt(2)")
    assert_equals(repr((A * B).pnorm()), "sqrt(65)")
    assert_equals(repr((A * B).inverse()), "(8 - e01 + e20 + e12) / 65")

    a = infPoint3D("a1", "a2", 0)
    b = infPoint3D("2b1", 0, 0)
    assert_equals(repr(a + b), "((a1 + 2b1)e1 + a2e2)")
    assert_equals(repr(a + b), "((a1 + 2b1)e1 + a2e2)")
    assert_equals(repr(a - b), "((a1 - 2b1)e1 + a2e2)")
    assert_equals(repr(a*b - a*b), "0")
    assert_equals(repr((a+b) * b), "((2(a1*b1) + 4(b1*b1)) - 2(a2*b1)e12)")

    A = point2D("a_1", "a_2")
    B = point2D("b_1", "b_2")

    move = infPoint2D("c_1", "c_2")
    assert_equals((A ^ B).direction(), ((A + move) ^ (B + move)).direction())
    assert_equals((A ^ B).dnorm(), ((A + move) ^ (B + move)).dnorm())

    move_along_line = infPoint2D("(b_1-a_1)", "(b_2-a_2)")
    assert_equals((A ^ B).direction(), ((A + move_along_line) ^ (B + move_along_line)).direction())
    assert_equals((A ^ B).position(), ((A + move_along_line) ^ (B + move_along_line)).position())

    A = point3D("a_1", "a_2", "a_3")
    B = point3D("b_1", "b_2", "b_3")
    assert_equals(
        repr(A ^ B),
        "((-a_1 + b_1)e01 + (-a_2 + b_2)e02 + (-a_3 + b_3)e03 + ((a_1*b_2) - (a_2*b_1))e12 + (-(a_1*b_3) + (a_3*b_1))e31 + ((a_2*b_3) - (a_3*b_2))e23)"
    )

if __name__ == "__main__":
    run_tests()
