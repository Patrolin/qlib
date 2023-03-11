from qlib.tests import assert_equals, test, run_tests
from qlib.math import E, TAU, PI, phi1, phi2, phi3, phi4

@test
def testMathConstants():
    assert_equals(E, 2.718281828459045)
    assert_equals(TAU, 6.283185307179586)
    assert_equals(PI, 3.141592653589793)
    assert_equals(phi1, 1.618033988749895)
    assert_equals(phi2, 1.3247179572447458)
    assert_equals(phi3, 1.2207440846057596)
    assert_equals(phi4, 1.1673039782614185)

if __name__ == "__main__":
    run_tests()
