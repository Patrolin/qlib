from qLib.quiteok import decodeQuiteOK, readQuiteOK, encodeQuiteOK, writeQuiteOK, QoiImage
from qLib import relative_path, test, run_tests

def encode_u8(u8: int) -> bytes:
    assert 0 <= u8 < 256
    return u8.to_bytes(1, "big")

def encode_u32(u32: int) -> bytes:
    assert 0 <= u32 < 2**32
    return u32.to_bytes(4, "big")

def RGBA(u32: int) -> tuple[int, int, int, int]:
    R = u32 >> 24
    G = (u32 >> 16) & 0xff
    B = (u32 >> 8) & 0xff
    A = u32 & 0xff
    assert (0 <= R < 256) and (0 <= G < 256) and (0 <= B < 256) and (0 <= A < 256)
    return (R, G, B, A)

class TestCase:
    def __init__(self, image: QoiImage, bytes: bytes):
        self.image = image
        self.bytes = bytes
        self.i = 0

    def add(self, color: int, bytes: bytes, n=1):
        for k in range(n):
            self.image.data[self.i + k] = color
        self.i += n
        self.bytes += bytes

def makeTestCase(width: int, height: int, channels: int, isLinear: bool) -> TestCase:
    return TestCase( \
        QoiImage(width, height, isLinear),
        b"qoif" + encode_u32(width) + encode_u32(height) + b"\x04" + encode_u8(int(isLinear))
    )

BLACK = 0x0000_00ff
WHITE = 0xffff_ffff

def QOI_OP_RGBA(color: int) -> bytes:
    R, G, B, A = RGBA(color)
    return b"\xff" + encode_u8(R) + encode_u8(G) + encode_u8(B) + encode_u8(A)

def QOI_OP_RGB(color: int) -> bytes:
    R, G, B, A = RGBA(color)
    return b"\xfe" + encode_u8(R) + encode_u8(G) + encode_u8(B)

def QOI_OP_INDEX(color: int) -> bytes:
    R, G, B, A = RGBA(color)
    j = (R*3 + G*5 + B*7 + A*11) & 0x3f
    return encode_u8((0b00 << 6) + j)

def QOI_OP_DIFF(dR: int, dG: int, dB: int) -> bytes:
    assert (-2 <= dR <= 1) and (-2 <= dG <= 1) and (-2 <= dB <= 1)
    return encode_u8((0b01 << 6) + ((dR + 2) << 4) + ((dG + 2) << 2) + (dB+2))

def QOI_OP_LUMA(dG: int, dRdG: int, dBdG: int) -> bytes:
    assert (-32 <= dG <= 31) and (-8 <= dRdG <= 7) and (-8 <= dBdG <= 7)
    return encode_u8((0b10 << 6) + (dG+32)) + encode_u8(((dRdG + 8) << 4) + (dBdG+8))

def QOI_OP_RUN(n: int) -> bytes:
    assert 0 <= n <= 61
    return encode_u8((0b11 << 6) + n)

pixelTest = makeTestCase(1, 1, channels=3, isLinear=True)
pixelTest.add(BLACK, QOI_OP_RUN(0))

coverageTest = makeTestCase(89, 51, channels=4, isLinear=False)
coverageTest.add(BLACK, QOI_OP_RUN(0))
coverageTest.add(WHITE, QOI_OP_DIFF(-1, -1, -1))
coverageTest.add(BLACK, QOI_OP_DIFF(1, 1, 1))
for n in range(62):
    coverageTest.add(WHITE, QOI_OP_INDEX(WHITE) + QOI_OP_RUN(n), n=n + 2)
    coverageTest.add(BLACK, QOI_OP_INDEX(BLACK) + QOI_OP_RUN(n), n=n + 2)
for n in range(62, 65):
    coverageTest.add(WHITE, QOI_OP_INDEX(WHITE) + QOI_OP_RUN(61) + QOI_OP_RUN(n - 62), n=n + 2)
    coverageTest.add(BLACK, QOI_OP_INDEX(BLACK) + QOI_OP_RUN(61) + QOI_OP_RUN(n - 62), n=n + 2)
coverageTest.add(0x0000_00fe, QOI_OP_RGBA(0x0000_00fe))
coverageTest.add(0x0100_fefe, QOI_OP_DIFF(1, 0, -2))
coverageTest.add(0xff01_fffe, QOI_OP_DIFF(-2, 1, 1))
coverageTest.add(0xfeff_fefe, QOI_OP_DIFF(-1, -2, -1))
coverageTest.add(0xfe7f_fefe, QOI_OP_RGB(0xfe7f_fefe))
coverageTest.add(0xde5f_defe, QOI_OP_LUMA(-32, 0, 0))
coverageTest.add(0xf57e_04fe, QOI_OP_LUMA(31, -8, 7))
coverageTest.add(0xfc7e_fcfe, QOI_OP_LUMA(0, 7, -8))
for n in range(9):
    coverageTest.add(WHITE, QOI_OP_INDEX(WHITE) + QOI_OP_RUN(n), n=n + 2)
    coverageTest.add(BLACK, QOI_OP_INDEX(BLACK) + QOI_OP_RUN(n), n=n + 2)

def printBytes(bytes: bytes) -> str:
    return "".join(f"\\x{v:02x}" for v in bytes)

#print(printBytes(coverageTest.bytes[:14]))
#print(printBytes(coverageTest.bytes[14:]))

def assertImageMatches(image1: QoiImage, image2: QoiImage):
    assert image1.width == image2.width
    assert image1.height == image2.height
    assert image1.isLinear == image2.isLinear
    for y in range(image1.height):
        for x in range(image1.width):
            i = y * image1.width + x
            if image1.data[i] != image2.data[i]:
                assert False, image1.print(0, y, image1.width)

def assertBytesMatch(qoi1: bytes, qoi2: bytes):
    for i in range(len(qoi2)):
        if i >= len(qoi1):
            assert False, f"Missing bytes at {i}:\n    expected: {printBytes(qoi2[i:])}"
        if qoi1[i] != qoi2[i]:
            assert False, f"Bytes differ at {i}:\n    got:      {printBytes(qoi1[:i+1])}\n    expected: {printBytes(qoi2[:i+1])}"
    if len(qoi1) > len(qoi2):
        assert False, f"Extra bytes at {len(qoi2)+1}:\n    got: {printBytes(qoi1[len(qoi2)+1:])}"

@test
def testDecodeQuiteOK():
    assertImageMatches(decodeQuiteOK(pixelTest.bytes), pixelTest.image)
    assertImageMatches(decodeQuiteOK(coverageTest.bytes), coverageTest.image)

@test
def testEncodeQuiteOK():
    assertBytesMatch(encodeQuiteOK(pixelTest.image), pixelTest.bytes)
    assertBytesMatch(encodeQuiteOK(coverageTest.image), coverageTest.bytes)

@test
def testDecodeQuiteOKIsReversible():
    assertBytesMatch(encodeQuiteOK(decodeQuiteOK(pixelTest.bytes)), pixelTest.bytes)
    assertBytesMatch(encodeQuiteOK(decodeQuiteOK(coverageTest.bytes)), coverageTest.bytes)

@test
def testEncodeQuiteOKIsReversible():
    assertImageMatches(decodeQuiteOK(encodeQuiteOK(pixelTest.image)), pixelTest.image)
    assertImageMatches(decodeQuiteOK(encodeQuiteOK(coverageTest.image)), coverageTest.image)

def assertWriteAndReadQuiteOK(path: str, testCase: TestCase):
    writeQuiteOK(path, testCase.image)
    assertImageMatches(readQuiteOK(path), testCase.image)

@test
def testWriteAndReadQuiteOK():
    assertWriteAndReadQuiteOK(relative_path(__file__, "/data/pixelTest.qoi"), pixelTest)
    assertWriteAndReadQuiteOK(relative_path(__file__, "/data/coverageTest.qoi"), coverageTest)

if __name__ == "__main__":
    run_tests()
