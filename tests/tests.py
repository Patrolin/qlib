from qLib import *

@test
def testPassTest():
    assert_(True)

if __name__ == "__main__":

    @test
    def testFailTest():
        assert_never("Fail test")

    @test
    def testIntError():
        int("z")

    run_tests()
