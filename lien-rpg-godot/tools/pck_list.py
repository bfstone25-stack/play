#!/usr/bin/env python3
"""List the files inside a Godot 4.7 .pck (pack format 4: the directory sits at an offset
named in the header), so a trial build can be checked for leaks."""
import struct, sys


def pck_files(path):
    with open(path, "rb") as f:
        assert f.read(4) == b"GDPC", "not a pck"
        fmt, major, minor, patch = struct.unpack("<IIII", f.read(16))
        flags, = struct.unpack("<I", f.read(4))
        file_base, dir_off = struct.unpack("<QQ", f.read(16))
        if fmt >= 3 and dir_off:
            f.seek(dir_off)
        else:
            f.seek(4 + 16 + 4 + 8 + 16 * 4)
        n, = struct.unpack("<I", f.read(4))
        out = []
        for _ in range(n):
            ln, = struct.unpack("<I", f.read(4))
            p = f.read(ln).rstrip(b"\0").decode()
            off, size = struct.unpack("<QQ", f.read(16))
            f.read(16)                        # md5
            fl, = struct.unpack("<I", f.read(4))
            out.append((p, size))
        return out


if __name__ == "__main__":
    for p, s in pck_files(sys.argv[1]):
        print(s, p)
