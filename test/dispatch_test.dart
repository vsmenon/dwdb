// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import "package:dwdb/dispatch.dart";
import "package:test/test.dart";

void main() {
  ServiceDispatcher dispatcher;

  dispatch(String input) => dispatcher.input.add(json.decode(input));

  setUp(() async {
    dispatcher = ServiceDispatcher('localhost', 9222);
    await dispatcher.service.ready;
  });

  test("stream listen/cancel", () async {
    dispatch(
        '{"id":"0","method":"streamListen","params":{"streamId":"Isolate"}}');
    dispatch(
        '{"id":"1","method":"streamListen","params":{"streamId":"Isolate"}}');
    dispatch(
        '{"id":"2","method":"streamListen","params":{"streamId":"Debug"}}');
    dispatch(
        '{"id":"3","method":"streamCancel","params":{"streamId":"Isolate"}}');
    dispatch(
        '{"id":"4","method":"streamCancel","params":{"streamId":"Isolate"}}');

    expect(
        dispatcher.output,
        emitsInOrder([
          allOf(containsPair('id', '0'), contains('result')),
          allOf(containsPair('id', '1'), contains('error')),
          allOf(containsPair('id', '2'), contains('result')),
          allOf(containsPair('id', '3'), contains('result')),
          allOf(containsPair('id', '4'), contains('error')),
        ]));
  });
}
