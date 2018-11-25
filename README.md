# homebridge_install_script

Just a small script which installs and configures [homebridge](https://www.github.com/nfarina/homebridge), [cmdSwitch2](https://www.npmjs.com/package/homebridge-cmdswitch2) and [rc-switch](https://github.com/sui77/rc-switch) library with 433mhz support Rhine ceiling fan(s) and various no-name outlets.


## Installation

Enter these commands on a freshly installed raspbian:

```shell
wget https://raw.githubusercontent.com/somebodywhoisntme/homebridge_install_script/master/install_homebridge.sh

chmod +x install_homebridge.sh

./install_homebridge.sh

```

Follow screen instructions.

When photo was taken from QR-Code press 'q'.





## Configuration

The homebridge config.json is located at /var/homebridge/

```shell
sudo nano /var/homebridge/config.json

```

Syntax ceiling fan:
```
  send [protocol number] [command] [0] [0]
```
The last two 0's are needed because I don't know a better way to prevent a seg-fault atm but they don't have a purpose.

Syntax outlet:
```
  send [protocol number] [system code] [device ID] [command]
```

Homebridge config.json example with ceiling fan stage 1/off button and one outlet.  
```javascript
"platform" : "cmdSwitch2",
"name": "CMD Switch",
"switches": [{
    "name" : "Fan",
    "on_cmd": "sudo /var/homebridge/send 8 119 0 0",
    "off_cmd": "sudo /var/homebridge/send 8 125 0 0"
  }, {
    "name" : "Outlet",
    "on_cmd": "sudo /var/homebridge/send 2 1 1 1",
    "off_cmd": "sudo /var/homebridge/send 2 1 1 0"
 }]
 ```
