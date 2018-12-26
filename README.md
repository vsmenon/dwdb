# dwdb
Dart Web Debugger

This is a not very functional proof-of-concept proxy between Chrome's debugger protocol and the Dart VM's protocol.

Instructions:
- Run chrome with the debugging port open: chrome --user-data-dir=/tmp/dwdb --remote-debugging-port=9222 <url-to-ddc-app>
- Run the proxy: dart bin/proxy.dart
- Open VSCode (with the Dart plugin) on a file in the app above.
- In VSCode, add a "Dart Attach" debug configuration and "Start Debugging".
