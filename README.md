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


## Usage

```sh
node service.js --help
Usage : gtrl <cmd> [params]
[backup | bak] <dir>   : Backup log.db
[--config | -c] <path> : Path to config file
[--setup | -s] <path>  : Path to setup file
[--help | -help | -h]  : Print usage
```

### Service

Start service
```sh
systemctl start gtrl.service
```

Show log
```sh
journalctl -u gtrl
```

Follow log
```sh
journalctl --follow -u gtrl
```
