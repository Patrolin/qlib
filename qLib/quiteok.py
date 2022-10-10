__all__ = ["decodeQuiteOK", "readQuiteOK", "encodeQuiteOK", "writeQuiteOK", "QoiImage"]

from qLib.math_ import lerp

def u32(R: int, G: int, B: int, A: int) -> int:
    return ((R << 24) + (G << 16) + (B << 8) + A)

def RGBA(u32: int) -> tuple[int, int, int, int]:
    R = u32 >> 24
    G = (u32 >> 16) & 0xff
    B = (u32 >> 8) & 0xff
    A = u32 & 0xff
    return (R, G, B, A)

def decode_u32(v: bytes) -> int:
    return u32(v[0], v[1], v[2], v[3])

def encode_u32(v: int) -> bytes:
    return v.to_bytes(4, byteorder="big")

def encode_u8(v: int) -> bytes:
    return v.to_bytes(1, byteorder="big")

class QoiImage:
    MAGIC = b"qoif"

    def __init__(self, width: int, height: int, isLinear: bool):
        self.data = [0] * (width * height)
        self.width = width
        self.height = height
        self.isLinear = isLinear

    def print(self, x: int, y: int, n: int):
        acc = f"-- {x} {y} --"
        for j in range(n):
            i = y * self.width + x + j
            acc += f"\n{RGBA(self.data[i]) if i < len(self.data) else None}"
        return acc

QOI_OP_RGB = 0xfe
QOI_OP_RGBA = 0xff
QOI_OP_INDEX = 0b00
QOI_OP_DIFF = 0b01
QOI_OP_LUMA = 0b10
QOI_OP_RUN = 0b11

def quiteOKHash(R: int, G: int, B: int, A: int) -> int:
    return (R * 3 + G * 5 + B * 7 + A * 11) & 0x3f

def decodeQuiteOK(qoi: bytes) -> QoiImage:
    # header
    assert qoi[0:4] == QoiImage.MAGIC
    width = decode_u32(qoi[4:8])
    height = decode_u32(qoi[8:12])
    channels = qoi[12]
    colorSpace = qoi[13]

    # data
    acc = QoiImage(width, height, colorSpace == 1)
    seen = [0] * 64
    R, G, B, A = 0, 0, 0, 255
    i = 0
    j = 14
    while i < len(acc.data):
        byte = qoi[j]
        j += 1
        if byte == QOI_OP_RGBA:
            R = qoi[j]
            G = qoi[j + 1]
            B = qoi[j + 2]
            A = qoi[j + 3]
            j += 4
        elif byte == QOI_OP_RGB:
            R = qoi[j]
            G = qoi[j + 1]
            B = qoi[j + 2]
            j += 3
        else:
            twoTag = byte >> 6
            if twoTag == QOI_OP_INDEX:
                R, G, B, A = RGBA(seen[byte & 0x3f])
            elif twoTag == QOI_OP_DIFF:
                dR = ((byte >> 4) & 0b11) - 2
                dG = ((byte >> 2) & 0b11) - 2
                dB = (byte & 0b11) - 2
                R = (R + dR) & 0xff
                G = (G + dG) & 0xff
                B = (B + dB) & 0xff
            elif twoTag == QOI_OP_LUMA:
                dG = (byte & 0x3f) - 32
                byte = qoi[j]
                j += 1
                dRdG = (byte >> 4) - 8
                dBdG = (byte & 0x0f) - 8
                R = (R + dRdG + dG) & 0xff
                G = (G + dG) & 0xff
                B = (B + dBdG + dG) & 0xff
            else: # QOI_OP_RUN
                n = (byte & 0x3f) + 1
                for k in range(n):
                    acc.data[i + k] = u32(R, G, B, A)
                seen[quiteOKHash(R, G, B, A)] = u32(R, G, B, A)
                i += n
                continue
        acc.data[i] = u32(R, G, B, A)
        seen[quiteOKHash(R, G, B, A)] = u32(R, G, B, A)
        i += 1
    return acc

def readQuiteOK(path: str) -> QoiImage:
    with open(path, "rb") as f:
        return decodeQuiteOK(f.read())

def smallest_difference_u8(b: int, a: int) -> int:
    d1 = (b - a) % 256
    d2 = d1 - 256
    return lerp(d1 >= 128, d1, d2)

def encodeQuiteOK(image: QoiImage) -> bytes:
    # header
    acc = b""
    acc += b"qoif"
    acc += encode_u32(image.width)
    acc += encode_u32(image.height)
    acc += encode_u8(4)
    acc += encode_u8(image.isLinear)

    # data
    seen = [0] * 64
    R, G, B, A = 0, 0, 0, 255
    i = 0
    while i < len(image.data):
        # QOI_OP_RUN
        if u32(R, G, B, A) == image.data[i]:
            n = 0
            for n in range(62):
                if i + n + 1 >= len(image.data) or u32(R, G, B, A) != image.data[i + n + 1]:
                    break
            acc += encode_u8((QOI_OP_RUN << 6) + n)
            i += n + 1
            continue

        newR, newG, newB, newA = RGBA(image.data[i])
        while 1:
            # QOI_OP_INDEX
            dR, dG, dB = smallest_difference_u8(newR, R), smallest_difference_u8(newG, G), smallest_difference_u8(newB, B)
            j = quiteOKHash(newR, newG, newB, newA)
            if seen[j] == image.data[i]:
                acc += encode_u8((QOI_OP_INDEX << 6) + j)
                break
            seen[j] = image.data[i]

            # QOI_OP_RGBA
            if newA != A:
                acc += encode_u8(QOI_OP_RGBA)
                acc += encode_u8(newR)
                acc += encode_u8(newG)
                acc += encode_u8(newB)
                acc += encode_u8(newA)
                break
            # QOI_OP_DIFF
            if (-2 <= dR <= 1) and (-2 <= dG <= 1) and (-2 <= dB <= 1):
                acc += encode_u8((QOI_OP_DIFF << 6) + ((dR + 2) << 4) + ((dG + 2) << 2) + (dB + 2))
                break
            # QOI_OP_LUMA
            dRdG = smallest_difference_u8(dR, dG)
            dBdG = smallest_difference_u8(dB, dG)
            if (-32 <= dG <= 31) and (-8 <= dRdG <= 7) and (-8 <= dBdG <= 7):
                acc += encode_u8((QOI_OP_LUMA << 6) + (dG + 32))
                acc += encode_u8(((dRdG + 8) << 4) + (dBdG + 8))
                break
            # QOI_OP_RGB
            acc += encode_u8(QOI_OP_RGB)
            acc += encode_u8(newR)
            acc += encode_u8(newG)
            acc += encode_u8(newB)
            break
        R, G, B, A = newR, newG, newB, newA
        i += 1
    return acc

def writeQuiteOK(path: str, image: QoiImage):
    with open(path, "wb+") as f:
        f.write(encodeQuiteOK(image))
