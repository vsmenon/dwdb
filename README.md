# dwdb
Dart Web Debugger

This is a not very functional proof-of-concept proxy between Chrome's debugger protocol and the Dart VM's protocol.
It's intended to support any VM service protocol client.  It's been developed against the 
[Flutter devtools](https://github.com/flutter/devtools), but may run with others (e.g., the Dart VSCode plugin).

Instructions:
- Run chrome with the debugging port open: chrome --user-data-dir=/tmp/dwdb --remote-debugging-port=9222 <url-to-ddc-app>
- Run the proxy: dart bin/proxy.dart
- Install and setup [Flutter devtools](https://github.com/flutter/devtools)
- Launch devtools: `pub run webdev serve web:9000`
- In a different Chrome instance, navigate to: [http://localhost:9000/?port=8181#debugger](http://localhost:9000/?port=8181#debugger)
