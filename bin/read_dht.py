#!/usr/bin/python

# import argparse
import json
import sys
import Adafruit_DHT

# print(sys.argv[1:])
args = sys.argv[1:]
# sensor_type = args[0]
sensor_pin = args[0]

sensor = Adafruit_DHT.DHT22
humidity, temperature = Adafruit_DHT.read_retry(sensor, sensor_pin)

print(json.dumps([temperature, humidity]))
