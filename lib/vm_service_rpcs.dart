// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart' as sm;
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
    scriptUri = _convertToBrowserUrl(scriptUri) ?? scriptUri;
    // TODO(vsm): Clean this up and factor it out.
    for (var mapping in _mappings) {
      for (var url in mapping.urls) {
        if (scriptUri.endsWith(url)) {
          for (var lineEntry in mapping.lines) {
            for (var entry in lineEntry.entries) {
              if (entry.sourceLine >= line) {
                // Just use this for now.
                // Check the url matches!
                // FIXME
                var fullUrl = p.join(p.dirname(scriptUri), mapping.targetUrl);
                var scriptId = _scriptIdMap[fullUrl];
                print('SCRIPTID: $fullUrl $scriptId (${scriptId.runtimeType})');
                // WIP uses zero-based numbering.
                var jsLine = lineEntry.line - 1;

                WipResponse result;
                try {
                  result = await _cdp.debugger
                      .sendCommand('Debugger.setBreakpoint', params: {
                    'location': {
                      'scriptId': scriptId,
                      'lineNumber': jsLine,
                    }
                  });
                } catch (e) {
                  throw RpcError(102)..data.details = '$e';
                }
                var breakpointId = result.result['breakpointId'];
                _streamNotify(
                    'Debug', Event()..kind = EventKind.BreakpointAdded);
                return _createBreakpoint();
              }
            }
          }
        }
      }
    }
  }

  String _convertToBrowserUrl(String fileUrl) {
    String suffix;
    var parts = p.split(fileUrl);
    // TODO(vsm): How do we robustly compute the package structure we're
    // currently in?  This can break if 'lib' or 'web' appear within the
    // package.
    for (var i = parts.length - 1; i > 0; --i) {
      var part = parts[i];
      if (part == 'lib') {
        var package = parts[i - 1];
        suffix = p.joinAll(parts.sublist(i +
            1)); // p.join('packages', package, p.joinAll(parts.sublist(i + 1)));
        break;
      } else if (part == 'web') {
        suffix = p.joinAll(parts.sublist(i + 1));
      }
    }
    if (suffix == null) return null;

    var lib = _libraries.keys
        .firstWhere((lib) => lib.uri.endsWith(suffix), orElse: () => null);
    return lib?.uri;
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
    var isolate = _vm
        .getIsolates()
        .firstWhere((i) => i.id == isolateId, orElse: () => null);

    return isolate ?? Sentinel();
  }

  Future<ScriptList> getScripts(String isolateId) async {
    Isolate isolate = await getIsolate(isolateId);
    var libraries = isolate.getLibraries();
    var scripts = <RefScript>[];
    for (var lib in libraries) {
      scripts.addAll(lib.scripts);
    }
    return ScriptList()..scripts = scripts;
  }

  Future<Object> /*VmObject|Sentinel*/ getObject(
      String isolateId, String objectId,
      {int offset, int count}) async {
    // TODO(vsm): Qualify to isolateId.
    return _objectMap[objectId];
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
    // TODO(vsm): Support multiple isolates.
    if (_vm.isolates.first.id == isolateId) {
      await _cdp.debugger.pause();
    }
    return Success();
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
    // TODO(vsm): Support multiple isolates.
    if (_vm.isolates.first.id == isolateId) {
      await _cdp.debugger.resume();
    }
    return Success();
  }

  Future<Success> setExceptionPauseMode(
      String isolateId, ExceptionPauseMode mode) async {
    PauseState chromeMode;
    switch (mode) {
      case ExceptionPauseMode.All:
        chromeMode = PauseState.all;
        break;
      case ExceptionPauseMode.Unhandled:
        chromeMode = PauseState.uncaught;
        break;
      case ExceptionPauseMode.None:
        chromeMode = PauseState.none;
        break;
    }
    await _cdp.debugger.setPauseOnExceptions(chromeMode);
    return Success();
  }

  Future<Success> setFlag(String name, String value) async {
    throw UnimplementedError('setFlag');
  }

  Future<Success> setLibraryDebuggable(
      String isolateId, String libraryId, bool isDebuggable) async {
    // TODO(vsm): Enable / disable debugging on this library.  We'll need to
    // figure out how to map to this granularity on a JS Script.
    return Success();
  }

  Future<Success> setName(String isolateId, String name) async {
    var isolate =
        _vm.getIsolates().firstWhere((i) => i.id == isolateId, orElse: null);
    if (isolate != null) isolate.name = name;
    return Success();
  }

  Future<Success> setVMName(String name) async {
    _vm.name = name;
    return Success();
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
    var isolate = _createIsolate();
    isolate
      ..name = '${tab.url}:main()'
      ..runnable = true
      ..pauseEvent = (Event()
        ..kind = EventKind.Resume
        ..isolate = isolate.toRef())
      ..breakpoints = [];
    _vm = VM()
      ..getIsolates().add(isolate)
      // TODO(vsm): This should be the DDC version, not the VM one.
      ..version = Platform.version;

    _cdp.runtime.enable();
    await _cdp.runtime
        .evaluate('console.log("Dart Web Debugger Proxy Running")');

    // Parse and map script in the browser back to Dart libraries.
    _cdp.debugger.enable();
    _cdp.debugger.onScriptParsed.listen((ScriptParsedEvent e) async {
      final WipScript script = e.script;
      var isolate = _vm.getIsolates().first;
      var libraries = isolate.getLibraries();

      String smUrl = script.sourceMapURL;
      if (smUrl != null && smUrl.isNotEmpty) {
        String sourceMapContents;
        sm.SingleMapping mapping;
        smUrl = p.join(p.dirname(script.url), smUrl);
        try {
          if (smUrl.startsWith('file://')) {
            smUrl = smUrl.substring('file://'.length);
            sourceMapContents = await File(smUrl).readAsString();
          } else {
            var request = await new HttpClient().postUrl(Uri.parse(smUrl));
            request.persistentConnection =
                false; // Use non-persistent connection.
            var response = await request.close();
            sourceMapContents = await response.transform(utf8.decoder).join();
          }
          // This may not be a single mapping.
          mapping = sm.parse(sourceMapContents) as sm.SingleMapping;
        } catch (e) {
          // No source map found.
          return;
        }
        _scriptIdMap[script.url] = script.scriptId;

        for (var src in mapping.urls) {
          // TODO(vsm): Support part files.
          var dartUrl = p.join(p.dirname(script.url), src);
          // TODO(vsm): Record this properly.
          var dartScript = _createScript()..uri = dartUrl;
          dartScript.tokenPosTable = [];
          var library = _createLibrary()
            ..uri = dartUrl
            ..getScripts().add(dartScript)
            ..name = p.basenameWithoutExtension(dartUrl);
          // TODO(vsm): Need a robust way to query for the root library.
          if (libraries.isEmpty) isolate.rootLib = library.toRef();
          libraries.add(library);
          _libraries[library] = script;
        }

        _mappings.add(mapping);
      }
    });

    _cdp.debugger.onPaused.listen((e) async {
      print('PAUSE: $e ${e.params}');
    });
    _cdp.debugger.onResumed.listen((e) async {});

    // TODO(vsm): Wait properly for page to load?
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      // We delay a small amount in order to allow the script information to
      // be populated as events.

      _initialized.complete();
    });
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

  T _create<T extends VmObject>(T Function() cons) {
    var id = _genId('$T');
    var obj = cons()..id = id;
    _objectMap[id] = obj;
    return obj;
  }

  Library _createLibrary() => _create(() => Library());

  Script _createScript() => _create(() => Script());

  Breakpoint _createBreakpoint() => _create(() => Breakpoint());

  Isolate _createIsolate() {
    var id = _genId('Isolate');
    var isolate = Isolate()..id = id;
    return isolate;
  }

  // Object Map: ID => Object.
  // TODO(vsm): Make this per isolate.
  Map<String, VmObject> _objectMap = {};

  // TODO(vsm): Make this per isolate?
  Set<WipScript> _scripts;
  Map<Library, WipScript> _libraries = {};
  final Map<String, String> _scriptIdMap = {};
  final List<sm.SingleMapping> _mappings = [];
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
