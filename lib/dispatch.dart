// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';

import 'vm_service_rpcs.dart';
import 'vm_service_types.dart';

/**
 * A mirror-based dispatch to the VM service APIs.
 * 
 * TODO: Codegen?
 */
class ServiceDispatcher {
  ServiceDispatcher(String host, int port) {
    service = Service(host, port, _streamNotify);
    _this = reflect(service);
    _class = _this.type;
    _input.stream.listen(_handle);
  }

  Service service;
  InstanceMirror _this;
  ClassMirror _class;

  StreamController<Map<String, Object>> _input = StreamController();
  StreamController<Map<String, Object>> _output = StreamController();

  StreamSink<Map<String, Object>> get input => _input.sink;
  Stream<Map<String, Object>> get output => _output.stream;

  Future get ready => service.ready;

  void _streamNotify(String streamId, Event event) {
    _output.add({
      "method": "streamNotify",
      "params": {"streamId": streamId, "event": _serialize(event)}
    });
  }

  Invocation _invocation(Symbol method, Map<String, Object> parameters) {
    var member = _class.instanceMembers[method];
    var positionals = [];
    var named = <Symbol, Object>{};

    var params = parameters.map((name, obj) => MapEntry(Symbol(name), obj));

    for (var p in member.parameters) {
      var type = p.type;
      var arg = params[p.simpleName];
      if (type is ClassMirror && type.isEnum) {
        // TODO(vsm): Auto-convert enums.
        throw UnimplementedError(
            'Enum type ${type.simpleName} not yet supported.');
      }
      if (!p.isNamed) {
        assert(!p.isOptional);
        positionals.add(arg);
      } else {
        named[p.simpleName] = arg;
      }
    }
    return Invocation.method(method, positionals, named);
  }

  Future<Object> _dispatch(Map<String, Object> request) async {
    try {
      var method = Symbol(request['method'] as String);
      var params =
          request['params'] as Map<String, Object> ?? <String, Object>{};
      var invocation = _invocation(method, params);
      return await _this.delegate(invocation);
    } catch (e) {
      var error = e is RpcError ? e : RpcError.unknown('$e');
      throw error;
    }
  }

  String _desymbol(Symbol symbol) {
    // Convert Symbol('foo') => foo.
    var str = '$symbol';
    return str.substring(8, str.length - 2);
  }

  bool _serializable(MethodMirror method) {
    if (method.isGetter) {
      var symbol = method.simpleName;
      var name = _desymbol(symbol);
      if (name != 'hashCode' && name != 'runtimeType') return true;
    }
    return false;
  }

  Object _serializeField(Object field) {
    if (field == null || field is bool || field is num || field is String)
      return field;
    assert(field is! Mirror);
    if (field is List) {
      return field.map(_serializeField).toList();
    }
    var instance = reflect(field);
    var cls = instance.type;
    if (cls.isEnum) {
      // Serialize Enums as Strings, but strip type name.
      var str = '$field';
      return str.split('.').sublist(1).join('.');
    }
    var map = <String, Object>{};
    var members = cls.instanceMembers;
    members.forEach((symbol, method) {
      if (_serializable(method)) {
        var name = _desymbol(method.simpleName);
        // Prune trailing _ for reserved words.
        if (name.endsWith('_')) name = name.substring(0, name.length - 1);
        var value =
            _serializeField(instance.getField(method.simpleName).reflectee);
        if (value != null) map[name] = value;
      }
    });
    return map;
  }

  Map<String, Object> _serialize(Object response) {
    return _serializeField(response);
  }

  void _handle(Map<String, Object> request) async {
    var id = request['id'];
    try {
      var response = await _dispatch(request);
      var result = _serialize(response);
      _output.add({'id': id, 'result': result});
    } on RpcError catch (error) {
      _output.add({'id': id, 'error': _serialize(error)});
    }
  }
}
