// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'vm_service_types.dart';

typedef StreamNotifier = void Function(String, Event);

/**
 * This is based on the Dart VM Service Protocol:
 * https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md
 * 
 * Version 3.13
 */
class Service {
  Future<Breakpoint> addBreakpoint(String isolateId, String scriptId, int line,
      {int column}) async {
    throw UnimplementedError('addBreakpoint');
  }

  Future<Breakpoint> addBreakpointWithScriptUri(
      String isolateId, String scriptUri, int line,
      {int column}) async {
    throw UnimplementedError('addBreakpointWithScriptUri');
  }

  Future<Breakpoint> addBreakpointAtEntry(
      String isolateId, String functionId) async {
    throw UnimplementedError('addBreakpointAtEntry');
  }

  Future<Object> /*RefInstance|RefError|Sentinel*/ invoke(String isolateId,
      String targetId, String selector, List<String> argumentIds) async {
    throw UnimplementedError('invoke');
  }

  Future<Object> /*RefInstance|RefError|Sentinel*/ evaluate(
      String isolateId, String targetId, String expression,
      {Map<String, String> scope}) async {
    throw UnimplementedError('evaluate');
  }

  Future<Object> /*RefInstance|RefError|Sentinel*/ evaluateInFrame(
      String isolateId, int frameIndex, String expression,
      {Map<String, String> scope}) async {
    throw UnimplementedError('evaluateInFrame');
  }

  Future<FlagList> getFlagList() async {
    throw UnimplementedError('getFlagList');
  }

  Future<Object> /*Isolate|Sentinel*/ getIsolate(String isolateId) async {
    var isolate =
        _isolates.firstWhere((i) => i.id == isolateId, orElse: () => null);

    return isolate ?? Sentinel();
  }

  Future<ScriptList> getScripts(String isolateId) async {
    throw UnimplementedError('getScripts');
  }

  Future<Object> /*VmObject|Sentinel*/ getObject(
      String isolateId, String objectId,
      {int offset, int count}) async {
    throw UnimplementedError('getObject');
  }

  Future<Stack> getStack(String isolateId) async {
    throw UnimplementedError('getStack');
  }

  Future<SourceReport> getSourceReport(
      String isolateId, List<SourceReportKind> reports,
      {String scriptId,
      int tokenPos,
      int endTokenPos,
      bool forceCompile}) async {
    throw UnimplementedError('getSourceReport');
  }

  Future<Version> getVersion() async {
    throw UnimplementedError('getVersion');
  }

  Future<VM> getVM() async {
    return _vm;
  }

  Future<Success> pause(String isolateId) async {
    throw UnimplementedError('pause');
  }

  Future<Success> kill(String isolateId) async {
    throw UnimplementedError('kill');
  }

  Future<ReloadReport> reloadSources(String isolateId,
      {bool force, bool pause, String rootLibUri, String packagesUri}) async {
    throw UnimplementedError('reloadSources');
  }

  Future<Success> removeBreakpoint(
      String isolateId, String breakpointId) async {
    throw UnimplementedError('removeBreakpoint');
  }

  Future<Success> resume(String isolateId,
      {StepOption step, int frameIndex}) async {
    throw UnimplementedError('resume');
  }

  Future<Success> setExceptionPauseMode(
      String isolateId, ExceptionPauseMode mode) async {
    throw UnimplementedError('setExceptionPauseMode');
  }

  Future<Success> setFlag(String name, String value) async {
    throw UnimplementedError('setFlag');
  }

  Future<Success> setLibraryDebuggable(
      String isolateId, String libraryId, bool isDebuggable) async {
    throw UnimplementedError('setLibraryDebuggable');
  }

  Future<Success> setName(String isolateId, String name) async {
    throw UnimplementedError('setName');
  }

  Future<Success> setVMName(String name) async {
    throw UnimplementedError('setVMName');
  }

  Future<Success> streamCancel(String streamId) async {
    if (_subscribedStreams.contains(streamId)) {
      _subscribedStreams.remove(streamId);
      return Success();
    } else {
      throw RpcError(104);
    }
  }

  Future<Success> streamListen(String streamId) async {
    if (!_subscribedStreams.contains(streamId)) {
      _subscribedStreams.add(streamId);
      return Success();
    } else {
      throw RpcError(103);
    }
  }

  Service(String host, int port, this._streamNotifier)
      : _chrome = ChromeConnection(host, port),
        _initialized = Completer() {
    _initialize();
  }

  int _objectId = 0;
  String _genId([String prefix = 'object']) => '$prefix/${_objectId++}';

  void _initialize() async {
    // TODO(vsm): For now, we find the first user tab and assume that's the one
    // to debug.  We also assume this is the one, single Dart isolate for now.

    // Find a Chrome 'Isolate'.
    final ChromeTab tab = await _chrome.getTab((ChromeTab tab) {
      return !tab.isBackgroundPage &&
          !tab.isChromeExtension &&
          !tab.url.startsWith("chrome-devtools://");
    });
    _cdp = await tab.connect();

    // Initialize the Dart 'VM'.
    _isolates = [
      Isolate()
        ..id = _genId('Isolate')
        ..name = tab.url
    ];
    _vm = VM()..isolates = _isolates.map((i) => i.toRef()).toList();

    _initialized.complete();
  }

  void _streamNotify(String streamId, Event e) {
    if (_subscribedStreams.contains(streamId)) _streamNotifier(streamId, e);
  }

  // Chrome Debug Protocol Connection.
  final ChromeConnection _chrome;
  WipConnection _cdp;

  // Callback to dispatch out-of-band Event objects.  See [streamListen] and
  // [streamCancel] below.
  final StreamNotifier _streamNotifier;

  final Set<String> _subscribedStreams = Set();

  // Indicater that this [Service] is initialized and ready.
  final Completer _initialized;
  Future get ready => _initialized.future;

  VM _vm;
  List<Isolate> _isolates;
}

class RpcErrorData {
  RpcErrorData(this.details);

  String details;
}

class RpcError {
  RpcError._(this.code, this.message, String details)
      : data = RpcErrorData(details);

  RpcError(int code) : this._(code, _errorCodes[code][0], _errorCodes[code][1]);

  RpcError.unknown([String message]) : this._(100, 'Unexpected error', message);

  int code;

  String message;

  RpcErrorData data;
}

Map<int, List<String>> _errorCodes = {
  100: [
    'Feature is disabled',
    'The operation is unable to complete because a feature is disabled'
  ],
  101: [
    'VM must be paused',
    'This operation is only valid when the VM is paused'
  ],
  102: [
    'Cannot add breakpoint',
    'The VM is unable to add a breakpoint at the specified line or function'
  ],
  103: [
    'Stream already subscribed',
    'The client is already subscribed to the specified streamId'
  ],
  104: [
    'Stream not subscribed',
    'The client is not subscribed to the specified streamId'
  ],
  105: [
    'Isolate must be runnable',
    'This operation cannot happen until the isolate is runnable'
  ],
  106: [
    'Isolate must be paused',
    'This operation is only valid when the isolate is paused'
  ],
  107: ['Cannot resume execution', 'The isolate could not be resumed'],
  108: [
    'Isolate is reloading',
    'he isolate is currently processing another reload request'
  ],
  109: [
    'Isolate cannot be reloaded',
    'The isolate has an unhandled exception and can no longer be reloaded'
  ],
  110: [
    'Isolate must have reloaded',
    'Failed to find differences in last hot reload request'
  ],
  111: [
    'Service already registered',
    'Service with such name has already been registered by this client'
  ],
  112: [
    'Service disappeared',
    'Failed to fulfill service request, likely service handler is no longer available'
  ],
  113: ['Expression compilation error', 'Request to compile expression failed'],
};
