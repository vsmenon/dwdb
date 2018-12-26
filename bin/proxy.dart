// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dwdb/dispatch.dart';
import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart' as sm;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

const bool temp = true;

void main(List<String> args) async {
  ArgParser parser = ArgParser()
    ..addOption('chrome', abbr: 'c', defaultsTo: '9222')
    ..addOption('dart', abbr: 'd', defaultsTo: '8181');
  var options = parser.parse(args);

  final int serviceProtocolPort = int.parse(options['dart']);
  final int devtoolsPort = int.parse(options['chrome']);

  final HttpServer server =
      await HttpServer.bind(InternetAddress.loopbackIPv4, serviceProtocolPort);

  print('Listening on ${server.port}');

  server.listen((HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket dart) {
      try {
        _handle(dart, 'localhost', devtoolsPort);
      } catch (e) {
        print(e);
        dart.close();
      }
    });
  });
}

T Function(T) _log<T>(String name) => (data) {
      print('$name $data');
      return data;
    };

void _handle(WebSocket dart, String host, int port) async {
  var dispatcher = ServiceDispatcher(host, port);
  await dispatcher.ready;

  dart
      .map(_log('<=='))
      .map<Map<String, Object>>((s) => json.decode(s))
      .pipe(dispatcher.input);
  dispatcher.output
      .map<Object>((s) => json.encode(s))
      .map(_log('==>'))
      .pipe(dart);
}
