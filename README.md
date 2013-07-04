ios-ota-maintainer [![build status](https://secure.travis-ci.org/seryl/node-ios-ota-maintainer.png?branch=master)](https://travis-ci.org/seryl/node-ios-ota-maintainer)
==================

Manages a certain level of archives for every application // branch // tags.

usage
-----

```bash
./bin/ios-ota-maintainer --help
Usage: node-ios-ota-maintainer

Options:
  -c, --config        The configuration file to use                        [default: "/etc/ios-ota-maintainer.json"]
  -H, --host          The host to connect to                               [default: "127.0.0.1"]
  -P, --port          The port to connect to                               [default: "3000"]
  -l, --loglevel      Set the log level (debug, info, warn, error, fatal)  [default: "warn"]
  -i, --interval      Clean interval (in milliseconds)                     [default: 900000]
  -m, --max-archives  Maximum number of archives for all branches/tags     [default: 50]
  -L, --loop          Runs the application in an event loop                [default: false]
  -h, --help          Shows this message                                   [default: false]
```
