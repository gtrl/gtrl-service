#!/usr/bin/python3

import sys
import struct
import Adafruit_DHT

args = sys.argv[1:]
pin = args[0]

sensor = Adafruit_DHT.DHT22
humidity, temperature = Adafruit_DHT.read(sensor, pin)
# humidity, temperature = Adafruit_DHT.read_retry(sensor, pin)

if humidity is not None and temperature is not None:
    sys.stdout.buffer.write(bytearray(struct.pack("f", temperature)))
    sys.stdout.buffer.write(bytearray(struct.pack("f", humidity)))
    exit(0)
else:
    exit(1)
