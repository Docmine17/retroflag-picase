#!/usr/bin/env python3
import signal
import subprocess
import sys
import time
import RPi.GPIO as GPIO

# Initialize pins (BCM numbering)
powerPin = 3    # Physical pin 5 (Power switch, active LOW)
ledPin = 14     # Physical pin 8 / TXD (Power LED, active HIGH)
resetPin = 2    # Physical pin 3 (Reset button, active LOW)
powerenPin = 4  # Physical pin 7 (Safe shutdown handshake, active HIGH)


def init():
	GPIO.setwarnings(False)
	GPIO.setmode(GPIO.BCM)
	GPIO.setup(powerPin, GPIO.IN, pull_up_down=GPIO.PUD_UP)
	GPIO.setup(resetPin, GPIO.IN, pull_up_down=GPIO.PUD_UP)
	GPIO.setup(ledPin, GPIO.OUT)
	GPIO.output(ledPin, GPIO.HIGH)
	GPIO.setup(powerenPin, GPIO.OUT)
	GPIO.output(powerenPin, GPIO.HIGH)


def handle_exit(signum, frame):
	# Keep powerenPin HIGH on service termination; do NOT call GPIO.cleanup()
	# so the case MCU only cuts power after the SoC resets.
	GPIO.output(powerenPin, GPIO.HIGH)
	GPIO.output(ledPin, GPIO.HIGH)
	sys.exit(0)


def monitor():
	while True:
		# Check power switch (LOW when turned off)
		if GPIO.input(powerPin) == GPIO.LOW:
			time.sleep(0.1)
			if GPIO.input(powerPin) == GPIO.LOW:
				subprocess.Popen(["/sbin/shutdown", "-r", "now"])
				while True:
					GPIO.output(ledPin, GPIO.LOW)
					time.sleep(0.2)
					GPIO.output(ledPin, GPIO.HIGH)
					time.sleep(0.2)

		# Check reset button (LOW when pressed)
		if GPIO.input(resetPin) == GPIO.LOW:
			time.sleep(0.1)
			if GPIO.input(resetPin) == GPIO.LOW:
				subprocess.Popen(["/sbin/shutdown", "-r", "now"])
				while True:
					GPIO.output(ledPin, GPIO.LOW)
					time.sleep(0.2)
					GPIO.output(ledPin, GPIO.HIGH)
					time.sleep(0.2)

		time.sleep(0.1)


if __name__ == "__main__":
	signal.signal(signal.SIGTERM, handle_exit)
	signal.signal(signal.SIGINT, handle_exit)
	init()
	monitor()

