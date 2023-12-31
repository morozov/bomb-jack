#!/usr/bin/env python3
import sys

def decode(b):
    # XOR A5
    b = b ^ 0xA5

    # RRCA
    b = (b >> 1) | ((b & 0x01) << 7)

    # ADD 0F
    b = (b + 0x0F) & 0xFF

    return b

input = sys.stdin.buffer.read()
output = bytes(map(decode, bytearray(input)))
sys.stdout.buffer.write(output)
