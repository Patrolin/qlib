from qlib import *

@test
def testPassTest():
    assert_(True)

if __name__ == "__main__":

    @test
    def testFailTest():
        assert_fail("Fail test")

    @test
    def testIntError():
        int("z")

    run_tests()
