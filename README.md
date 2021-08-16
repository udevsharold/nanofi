# NanoFi


## Speed up data transfer from iOS to Apple Watch rate

By default, Apple Watch prioritized Bluetooth connection, which makes transferring of music etc. very slow. NanoFi attempts to make WiFi as default connection. Note that your Apple Watch needs to be connected to local WiFi network (auto-join) for this to work.

It comes with a Control Center module. The module acts as an intermediate switch where sometimes the request to utilize WiFi failed due to Apple Watch not responsive to our request and you might want to re-request the operation. I have no control over this as without knowing how watchOS works internally, this is the best I could do.

## How to use this tweak?

You’ll have to activate NanoFi via the CC module (the switch in  Settings.app just act an master switch that will completely disable the tweak) it acts as an indicator of whether we successfully switch to wifi link. The hourglass indicates we're still trying to make the switch, and will change back to normal glyph when success. If it failed, the module will automatically revert back to off. It might failed for various reasons, one of it is your Apple Watch not responding (no handshake/ack received) to our request for switching. That’s where the toggle comes in handy, you could try to turn it back on if you want and the process will repeat. In the future I might think of it to automatically switch on (after we’ve failed) when it has active packets.


## Compatibility
This package tested to be working on iPhone X iOS 14.3, and with Apple Watch S5 on watchOS 7.3.3. Might or might not work on different combinations.

## License
All source code in this repository are licensed under GPLv3, unless stated otherwise.

Copyright (c) 2021 udevs
