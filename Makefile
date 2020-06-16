PRJ_NAME=musicBox
SERVICE_NAME=musicbox
HOSTNAME=$(shell hostname -s)
KEY_FILE_EXISTS=$(shell [ -f "./ifttt.key" ] && echo "true" || echo "false")
KEY=$(shell cat ./ifttt.key)

# Variables you can modify when running make
NUM_PIXELS?=72
START_AT?=00:18:00

NUM_PIXELS_MIN_1=$(shell expr $(NUM_PIXELS) - 1)

ifeq '$(KEY_FILE_EXISTS)' 'false'
$(error KEY env variable not set. Bailing out)
endif

.PHONY: help run_test watch wax-ibiza.mp3 blip.wav test-sounds audio-config send_udp install_service

all: run

run:
	python3 ./musicbox.py

help:
	@echo "make party &>/dev/null"
	@echo "make kill-party"

install: /home/pi/audio-reactive-led-strip audio-config
	sudo apt-get install espeak libatlas-base-dev -y
	pip3 install SpeechRecognition PyAudio numpy scipy 

service/help:
	@cat service.help.txt

service/install:
	sudo cp $(SERVICE_NAME).service /etc/systemd/system/$(SERVICE_NAME).service
	sudo systemctl daemon-reload

service/uninstall:
	sudo rm -f /etc/systemd/system/$(SERVICE_NAME).service
	sudo systemctl daemon-reload

service/check:
	@sudo systemctl is-enabled --quiet $(SERVICE_NAME) && echo enabled || echo disabled
	@sudo systemctl is-active --quiet $(SERVICE_NAME) && echo active || echo not-active

service/start_at_boot:
	sudo systemctl enable $(SERVICE_NAME)

service/start:
	sudo systemctl start $(SERVICE_NAME)

service/stop:
	sudo systemctl stop $(SERVICE_NAME)

service/logs:
	sudo journalctl -u $(SERVICE_NAME).service

office_on: office_main_on colors_left_on colors_right_on
office_off: office_main_off colors_left_off colors_right_off

strip_bottom_off strip_bottom_on \
office_main_off office_main_on \
colors_left_off colors_left_on \
colors_right_off colors_right_on \
office_table_on office_table_off \
test_on test_off:
	curl https://maker.ifttt.com/trigger/$@/with/key/$(KEY)

/home/pi/audio-reactive-led-strip:
	cd ;\
	git clone https://github.com/scottlawsonbc/audio-reactive-led-strip.git;\

audio-config: /home/pi/audio-reactive-led-strip
	cp config.py $</python/e

party: play cycle_office_table colors_right_on colors_left_on send_udp

send_udp: /home/pi/audio-reactive-led-strip
	(sleep 2; /usr/bin/python3 $</python/visualization.py 192.168.8.150) &>/dev/null	&
	(sleep 2; /usr/bin/python3 $</python/visualization.py 192.168.8.149) &>/dev/null	&

kill-party: kill-music kill-udp cycle_office_table colors_right_off colors_left_off

kill-udp:
	ONE=`ps -axuww | grep -v grep |grep visu | grep 150 | awk '{print $$2}'`;\
	TWO=`ps -axuww | grep -v grep |grep visu | grep 149 | awk '{print $$2}'`;\
	kill -9 $$ONE $$TWO

kill-music:
	OX=`ps -axuww | grep -v grep | grep omxplayer.bin | awk '{print $$2}'`;\
	kill -9 $$OX

cycle_office_table:
	curl https://maker.ifttt.com/trigger/office_table_off/with/key/$(KEY);\
	sleep 3;\
	curl https://maker.ifttt.com/trigger/office_table_on/with/key/$(KEY);\

strip-off:
	make  off IP=192.168.8.150; make  off IP=192.168.8.149

strip-on:
	make  on IP=192.168.8.150; make  on IP=192.168.8.149

ifeq ($(HOSTNAME), Rufus)
test-sounds: wax-ibiza.mp3 blip.wav

wax.ibiza.mp3:
	scp $@ $(IP):$(PRJ_NAME)/

blip.wav:
	rm -f blip.mp3; ffmpeg -i $@ -vn -ar 44100 -ac 2 -b:a 192k blip.mp3
	scp $@ $< $(IP):$(PRJ_NAME)/
endif

play:
	echo "Starting music .... in 2 seconds";\
	sleep 2; omxplayer -o alsa:hw:0,0 --pos $(START_AT) wax.ibiza.mp3 & 

ifdef IP

.ONESHELL:
SHELL = /bin/bash
on:
	s="";\
	for i in `seq 0 $(NUM_PIXELS_MIN_1)`;do s="$$s\x$$(printf '%02x' $$i)${ON_COLOR}"; done;\
	echo $$s;\
	echo -e $$s | nc -u -w1 $(IP) 7777

.ONESHELL:
SHELL = /bin/bash
off:
	for i in `seq 0 $(NUM_PIXELS_MIN_1)`;do s="$$s\x$$(printf '%02x' $$i)\x00\x00\x00"; done;\
	echo $$s;\
	echo -e $$s | nc -u -w1 $(IP) 7777

watch:
	chmod 755 *.py
	watcher -startcmd -cmd "rsync --exclude=.git -avz ../$(PRJ_NAME) $(IP):." -list *
endif
