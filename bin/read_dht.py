#!/usr/bin/python3

import sys
import struct
import Adafruit_DHT

sensor = Adafruit_DHT.DHT22

while True:
    pin = int.from_bytes(sys.stdin.buffer.raw.read(1), byteorder='little')
    humidity, temperature = Adafruit_DHT.read_(sensor, pin)
    if humidity is not None and temperature is not None:
        sys.stdout.buffer.write(bytearray(struct.pack("f", temperature)))
        sys.stdout.buffer.write(bytearray(struct.pack("f", humidity)))
    else:
        sys.stdout.buffer.write(bytearray(struct.pack("B", 0)))
    sys.stdout.flush()
