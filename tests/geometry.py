from qlib.tests import test, run_tests
from qlib.geometry import *

#@test
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

#@test
def testWedge():
    for G in (PGA_2D, PGA_3D, PGA_4D, CGA_2D, CGA_3D):
        G.assert_functions_match(lambda a, b: a & b, lambda a, b: (a.dual() ^ b.dual()).undual())
        G.assert_functions_match(lambda a, b: a ^ b, lambda a, b: (a.dual() & b.dual()).undual())

@test
def testMultivector():
    p1 = point2D(1, 2)
    assert_equals(repr(p1), "(e0 + e1 + 2e2)")
    p2 = point2D(2, 3)
    assert_equals(repr(p2), "(e0 + 2e1 + 3e2)")
    assert_equals(repr(p1 * p2), "(8 + e01 - e12 - e20)")
    assert_equals(repr((p1 * p2).dnorm()), "sqrt(2)")
    assert_equals(repr((p1 * p2).pnorm()), "sqrt(65)")
    assert_equals(repr((p1 * p2).inverse()), "(8 - e01 + e12 + e20) / 65")

    p1 = infPoint3D("a1", "a2", 0)
    p2 = infPoint3D("2b1", 0, 0)
    assert_equals(repr(p1 + p2), "((a1 + 2b1)e1 + a2e2)")
    assert_equals(repr(p1 + p2), "((a1 + 2b1)e1 + a2e2)")
    assert_equals(repr(p1 - p2), "((a1 - 2b1)e1 + a2e2)")
    assert_equals(repr(p1*p2 - p1*p2), "0")
    assert_equals(repr((p1+p2) * p2), "((2(a1 b1) + 4(b1 b1)) - 2(a2 b1)e12)")

    p1 = point2D("a_1", "a_2")
    p2 = point2D("b_1", "b_2")

    move = infPoint2D("c_1", "c_2")
    assert_equals((p1 ^ p2).direction(), ((p1 + move) ^ (p2 + move)).direction())

    move_along_line = infPoint2D("(b_1-a_1)", "(b_2-a_2)")
    assert_equals(repr(move_along_line), "((-a_1 + b_1)e1 + (-a_2 + b_2)e2)")
    assert_equals((p1 ^ p2).direction(), ((p1 + move_along_line) ^ (p2 + move_along_line)).direction())
    assert_equals((p1 ^ p2).position(), ((p1 + move_along_line) ^ (p2 + move_along_line)).position())

    p1 = point3D("a_1", "a_2", "a_3")
    p2 = point3D("b_1", "b_2", "b_3")
    assert_equals(
        repr(p1 ^ p2), """(
  (-a_1 + b_1)e01
  + (-a_2 + b_2)e02
  + (-a_3 + b_3)e03
  + ((a_1 b_2) - (a_2 b_1))e12
  + ((a_2 b_3) - (a_3 b_2))e23
  + (-(a_1 b_3) + (a_3 b_1))e31
)""")

    top = VGA_3D.parse_multivector("e1")[0]
    latLng = VGA_3D.parse_multivector("cos_LAT*cos_LNG + (cos_LAT*sin_LNG*e13) + (sin_LAT*cos_LNG*e12) - (sin_LAT*sin_LNG*e23)")[0]
    assert_equals(repr(latLng), """(
  (cos_LAT cos_LNG)
  + (cos_LNG sin_LAT)e12
  + (cos_LAT sin_LNG)e13
  - (sin_LAT sin_LNG)e23
)""")
    #print(latLng)
    #print(latLng * top * ~latLng)

if __name__ == "__main__":
    run_tests()
