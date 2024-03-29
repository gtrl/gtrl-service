PROJECT = gtrl
PREFIX ?= /usr
INSTALL_DIR ?= $(PREFIX)
SRC = $(wildcard src/**/*.hx)

all: build

service.js: $(SRC)
	haxe build.hxml

build: service.js

install:
	ln -snf $(shell pwd) $(INSTALL_DIR)/lib/$(PROJECT)
	cp gtrl.sh $(INSTALL_DIR)/bin/$(PROJECT)
	chmod +x $(INSTALL_DIR)/bin/$(PROJECT)
	cp gtrl.service /etc/systemd/system/
	systemctl daemon-reload

uninstall:
	rm -f $(INSTALL_DIR)/lib/$(PROJECT)
	rm -f $(INSTALL_DIR)/bin/$(PROJECT)
	rm -f /etc/systemd/system/$(PROJECT).service

clean:
	rm -f service.js*
