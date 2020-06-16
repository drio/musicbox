from gpiozero import DistanceSensor, LED, TonalBuzzer
from signal import pause
from gpiozero.tones import Tone
import time
import os

DISTANCE_ON_IDLE = 0.2

led_green = LED(16)
led_red = LED(12)

def led_test(led):
    led.off()
    led.on()
    time.sleep(.3)
    led.off()

def distance():
    sensor = DistanceSensor(echo=23, trigger=24)
    while True:
        print('Distance to nearest object is', sensor.distance, 'm')
        time.sleep(.5)

def party_time():
    sensor = DistanceSensor(echo=23, trigger=24)
    party_on = False
    led_red.off()
    while True:
        if sensor.distance < DISTANCE_ON_IDLE:
            if party_on:
                party_on = False
                led_green.off()
                os.system("make kill-party &>/dev/null &")
            else:
                party_on = True
                led_green.on()
                os.system("make party &>/dev/null &")
            print("Sleeping for 5 secs...")
            led_red.on()
            time.sleep(5)
            led_red.off()
        time.sleep(.05)

led_test(led_green); led_test(led_red)
led_test(led_green); led_test(led_red)
party_time()
#distance()
