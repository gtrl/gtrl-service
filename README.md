
GTRL
====
Sensor data logging service.


## Build/Install

```sh
## Install required npm packages
npm install

## Build service
make

## Install as linux service
make install
```


## Run

```sh
## Optional reload systemd if gtrl.service changed
systemctl daemon-reload

## Start service
systemctl start gtrl.service

## Show log
journalctl -u gtrl

## Follow log
journalctl --follow -u gtrl
```
