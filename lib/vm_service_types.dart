// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is based on the Dart VM Service Protocol:
 * https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md
 * 
 * Version 3.13
 */

class BoundField {
  FieldRef decl;
  Object /*InstanceRef|Sentinel*/ value;
}

class BoundVariable {
  String name;
  Object /*InstanceRef|TypeArgumentsRef|Sentinel*/ value;

  // The token position where this variable was declared.
  int declarationTokenPos;

  // The first token position where this variable is visible to the scope.
  int scopeStartTokenPos;

  // The last token position where this variable is visible to the scope.
  int scopeEndTokenPos;
}

class Breakpoint extends Obj {
  Breakpoint() : super('Breakpoint');

  // A number identifying this breakpoint to the user.
  int breakpointNumber;

  // Has this breakpoint been assigned to a specific program location?
  bool resolved;

  // Is this a breakpoint that was added synthetically as part of a step
  // OverAsyncSuspension resume command?
  bool isSyntheticAsyncContinuation;

  // SourceLocation when breakpoint is resolved, UnresolvedSourceLocation
  // when a breakpoint is not resolved.
  Object /*SourceLocation|UnresolvedSourceLocation*/ location;

  ObjRef toRef() =>
      throw UnsupportedError('Breakpoint cannot be converted to reference');
}

class ClassRef extends ObjRef {
  ClassRef(String id, this.name) : super('@Class', id);

  // The name of this class.
  final String name;
}

class Class extends Obj {
  Class() : super('Class');

  // The name of this class.
  String name;

  // The error which occurred during class finalization, if it exists.
  ErrorRef error = null;

  // Is this an abstract class?
  bool abstract_;

  // Is this a const class?
  bool const_;

  // The library which contains this class.
  LibraryRef library;

  // The location of this class in the source code.
  SourceLocation location = null;

  // The superclass of this class, if any.
  ClassRef super_ = null;

  // The supertype for this class, if any.
  //
  // The value will be of the kind: Type.
  InstanceRef superType = null;

  // A list of interface types for this class.
  //
  // The values will be of the kind: Type.
  List<InstanceRef> interfaces;

  // The mixin type for this class, if any.
  //
  // The value will be of the kind: Type.
  InstanceRef mixin = null;

  // A list of fields in this class. Does not include fields from
  // superclasses.
  List<FieldRef> fields;

  // A list of functions in this class. Does not include functions
  // from superclasses.
  List<FuncRef> functions;

  // A list of subclasses of this class.
  List<ClassRef> subclasses;

  ClassRef toRef() => ClassRef(id, name);
}

class ClassList extends Response {
  ClassList() : super('ClassList');

  List<ClassRef> classes;
}

class CodeRef extends ObjRef {
  CodeRef(String id, this.name, this.kind) : super('@Code', id);

  // A name for this code object.
  final String name;

  // What kind of code object is this?
  final CodeKind kind;
}

class Code extends Obj {
  Code() : super('Code');

  // A name for this code object.
  String name;

  // What kind of code object is this?
  CodeKind kind;

  CodeRef toRef() => CodeRef(id, name, kind);
}

enum CodeKind { Dart, Native, Stub, Tag, Collected }

class ContextRef extends ObjRef {
  ContextRef(String id, this.length) : super('@Context', id);

  // The number of variables in this context.
  final int length;
}

class Context extends Obj {
  Context() : super('Context');

  // The number of variables in this context.
  int length;

  // The enclosing context for this context.
  Context parent = null;

  // The variables in this context object.
  List<ContextElement> variables;

  ContextRef toRef() => ContextRef(id, length);
}

class ContextElement {
  Object /*InstanceRef|Sentinel*/ value;
}

class ErrorRef extends ObjRef {
  ErrorRef(String id, this.kind, this.message) : super('@Error', id);

  // What kind of error is this?
  final ErrorKind kind;

  // A description of the error.
  final String message;
}

class Error extends Obj {
  Error() : super('Error');

  // What kind of error is this?
  ErrorKind kind;

  // A description of the error.
  String message;

  // If this error is due to an unhandled exception, this
  // is the exception thrown.
  InstanceRef exception = null;

  // If this error is due to an unhandled exception, this
  // is the stacktrace object.
  InstanceRef stacktrace = null;

  ErrorRef toRef() => ErrorRef(id, kind, message);
}

enum ErrorKind {
  // The isolate has encountered an unhandled Dart exception.
  UnhandledException,

  // The isolate has encountered a Dart language error in the program.
  LanguageError,

  // The isolate has encounted an internal error. These errors should be
  // reported as bugs.
  InternalError,

  // The isolate has been terminated by an external source.
  TerminationError
}

class Event extends Response {
  Event() : super('Event');

  // What kind of event is this?
  EventKind kind;

  // The isolate with which this event is associated.
  //
  // This is provided for all event kinds except for:
  //   VMUpdate
  IsolateRef isolate = null;

  // The vm with which this event is associated.
  //
  // This is provided for the event kind:
  //   VMUpdate
  VMRef vm = null;

  // The timestamp (in milliseconds since the epoch) associated with this event.
  // For some isolate pause events, the timestamp is from when the isolate was
  // paused. For other events, the timestamp is from when the event was created.
  int timestamp;

  // The breakpoint which was added, removed, or resolved.
  //
  // This is provided for the event kinds:
  //   PauseBreakpoint
  //   BreakpointAdded
  //   BreakpointRemoved
  //   BreakpointResolved
  Breakpoint breakpoint = null;

  // The list of breakpoints at which we are currently paused
  // for a PauseBreakpoint event.
  //
  // This list may be empty. For example, while single-stepping, the
  // VM sends a PauseBreakpoint event with no breakpoints.
  //
  // If there is more than one breakpoint set at the program position,
  // then all of them will be provided.
  //
  // This is provided for the event kinds:
  //   PauseBreakpoint
  List<Breakpoint> pauseBreakpoints = null;

  // The top stack frame associated with this event, if applicable.
  //
  // This is provided for the event kinds:
  //   PauseBreakpoint
  //   PauseInterrupted
  //   PauseException
  //
  // For PauseInterrupted events, there will be no top frame if the
  // isolate is idle (waiting in the message loop).
  //
  // For the Resume event, the top frame is provided at
  // all times except for the initial resume event that is delivered
  // when an isolate begins execution.
  Frame topFrame = null;

  // The exception associated with this event, if this is a
  // PauseException event.
  InstanceRef exception = null;

  // An array of bytes, encoded as a base64 String.
  //
  // This is provided for the WriteEvent event.
  String bytes = null;

  // The argument passed to dart:developer.inspect.
  //
  // This is provided for the Inspect event.
  InstanceRef inspectee = null;

  // The RPC name of the extension that was added.
  //
  // This is provided for the ServiceExtensionAdded event.
  String extensionRPC = null;

  // The extension event kind.
  //
  // This is provided for the Extension event.
  String extensionKind = null;

  // The extension event data.
  //
  // This is provided for the Extension event.
  ExtensionData extensionData = null;

  // An array of TimelineEvents
  //
  // This is provided for the TimelineEvents event.
  List<TimelineEvent> timelineEvents = null;

  // Is the isolate paused at an await, yield, or yield* statement?
  //
  // This is provided for the event kinds:
  //   PauseBreakpoint
  //   PauseInterrupted
  bool atAsyncSuspension = null;

  // The status (success or failure) related to the event.
  // This is provided for the event kinds:
  //   IsolateReloaded
  //   IsolateSpawn
  String status = null;
}

enum EventKind {
  // Notification that VM identifying information has changed. Currently used
  // to notify of changes to the VM debugging name via setVMName.
  VMUpdate,

  // Notification that a new isolate has started.
  IsolateStart,

  // Notification that an isolate is ready to run.
  IsolateRunnable,

  // Notification that an isolate has exited.
  IsolateExit,

  // Notification that isolate identifying information has changed.
  // Currently used to notify of changes to the isolate debugging name
  // via setName.
  IsolateUpdate,

  // Notification that an isolate has been reloaded.
  IsolateReload,

  // Notification that an extension RPC was registered on an isolate.
  ServiceExtensionAdded,

  // An isolate has paused at start, before executing code.
  PauseStart,

  // An isolate has paused at exit, before terminating.
  PauseExit,

  // An isolate has paused at a breakpoint or due to stepping.
  PauseBreakpoint,

  // An isolate has paused due to interruption via pause.
  PauseInterrupted,

  // An isolate has paused due to an exception.
  PauseException,

  // An isolate has paused after a service request.
  PausePostRequest,

  // An isolate has started or resumed execution.
  Resume,

  // Indicates an isolate is not yet runnable. Only appears in an Isolate's
  // pauseEvent. Never sent over a stream.
  None,

  // A breakpoint has been added for an isolate.
  BreakpointAdded,

  // An unresolved breakpoint has been resolved for an isolate.
  BreakpointResolved,

  // A breakpoint has been removed.
  BreakpointRemoved,

  // A garbage collection event.
  GC,

  // Notification of bytes written, for example, to stdout/stderr.
  WriteEvent,

  // Notification from dart:developer.inspect.
  Inspect,

  // Event from dart:developer.postEvent.
  Extension
}

class ExtensionData {}

class FieldRef extends ObjRef {
  FieldRef(String id, this.name, this.owner, this.declaredType, this.const_,
      this.final_, this.static_)
      : super('@Field', id);

  // The name of this field.
  final String name;

  // The owner of this field, which can be either a Library or a
  // Class.
  final ObjRef owner;

  // The declared type of this field.
  //
  // The value will always be of one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  final InstanceRef declaredType;

  // Is this field const?
  final bool const_;

  // Is this field final?
  final bool final_;

  // Is this field static?
  final bool static_;
}

class Field extends Obj {
  Field() : super('Field');

  // The name of this field.
  String name;

  // The owner of this field, which can be either a Library or a
  // Class.
  ObjRef owner;

  // The declared type of this field.
  //
  // The value will always be of one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  InstanceRef declaredType;

  // Is this field const?
  bool const_;

  // Is this field final?
  bool final_;

  // Is this field static?
  bool static_;

  // The value of this field, if the field is static.
  InstanceRef staticValue = null;

  // The location of this field in the source code.
  SourceLocation location = null;

  FieldRef toRef() =>
      FieldRef(id, name, owner, declaredType, const_, final_, static_);
}

class Flag {
  // The name of the flag.
  String name;

  // A description of the flag.
  String comment;

  // Has this flag been modified from its default setting?
  bool modified;

  // The value of this flag as a String.
  //
  // If this property is absent, then the value of the flag was NULL.
  String valueAsString = null;
}

class FlagList extends Response {
  FlagList() : super('FlagList');

  // A list of all flags in the VM.
  List<Flag> flags;
}

class Frame extends Response {
  Frame() : super('Frame');

  int index;
  FuncRef function = null;
  CodeRef code = null;
  SourceLocation location = null;
  List<BoundVariable> vars = null;
  FrameKind kind = null;
}

class FuncRef extends ObjRef {
  FuncRef(String id, this.name, this.owner, this.static_, this.const_)
      : super('@Function', id);

  // The name of this function.
  final String name;
  // The owner of this function, which can be a Library, Class, or a Function.
  final Object /*LibraryRef|ClassRef|FuncRef*/ owner;

  // Is this function static?
  final bool static_;

  // Is this function const?
  final bool const_;
}

class Func extends Obj {
  Func() : super('Function');

  // The name of this function.
  String name;

  // The owner of this function, which can be a Library, Class, or a Function.
  Object /*LibraryRef|ClassRef|FuncRef*/ owner;

  // The location of this function in the source code.
  SourceLocation location = null;

  // The compiled code associated with this function.
  CodeRef code = null;

  // TODO(vsm): Do we need these?  Not in spec, but in ref class.
  // Is this function static?
  bool static_;

  // Is this function const?
  bool const_;

  FuncRef toRef() => FuncRef(id, name, owner, static_, const_);
}

class InstanceRef extends ObjRef {
  InstanceRef(String id, this.kind, this.class_) : super('@Instance', id);

  // What kind of instance is this?
  final InstanceKind kind;

  // Instance references always include their class.
  final ClassRef class_;

  // The value of this instance as a String.
  //
  // Provided for the instance kinds:
  //   Null (null)
  //   Bool (true or false)
  //   Double (suitable for passing to Double.parse())
  //   Int (suitable for passing to int.parse())
  //   String (value may be truncated)
  //   Float32x4
  //   Float64x2
  //   Int32x4
  //   StackTrace
  String valueAsString = null;

  // The valueAsString for String references may be truncated. If so,
  // this property is added with the value 'true'.
  //
  // New code should use 'length' and 'count' instead.
  bool valueAsStringIsTruncated = null;

  // The length of a List or the number of associations in a Map or the
  // number of codeunits in a String.
  //
  // Provided for instance kinds:
  //   String
  //   List
  //   Map
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  int length = null;

  // The name of a Type instance.
  //
  // Provided for instance kinds:
  //   Type
  String name = null;

  // The corresponding Class if this Type has a resolved typeClass.
  //
  // Provided for instance kinds:
  //   Type
  ClassRef typeClass = null;

  // The parameterized class of a type parameter:
  //
  // Provided for instance kinds:
  //   TypeParameter
  ClassRef parameterizedClass = null;

  // The pattern of a RegExp instance.
  //
  // The pattern is always an instance of kind String.
  //
  // Provided for instance kinds:
  //   RegExp
  InstanceRef pattern = null;
}

class Instance extends Obj {
  Instance() : super('Instance');

  // What kind of instance is this?
  InstanceKind kind;

  // Instance references always include their class.
  ClassRef class_;

  // The value of this instance as a String.
  //
  // Provided for the instance kinds:
  //   Bool (true or false)
  //   Double (suitable for passing to Double.parse())
  //   Int (suitable for passing to int.parse())
  //   String (value may be truncated)
  String valueAsString = null;

  // The valueAsString for String references may be truncated. If so,
  // this property is added with the value 'true'.
  //
  // New code should use 'length' and 'count' instead.
  bool valueAsStringIsTruncated = null;

  // The length of a List or the number of associations in a Map or the
  // number of codeunits in a String.
  //
  // Provided for instance kinds:
  //   String
  //   List
  //   Map
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  int length = null;

  // The index of the first element or association or codeunit returned.
  // This is only provided when it is non-zero.
  //
  // Provided for instance kinds:
  //   String
  //   List
  //   Map
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  int offset = null;

  // The number of elements or associations or codeunits returned.
  // This is only provided when it is less than length.
  //
  // Provided for instance kinds:
  //   String
  //   List
  //   Map
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  int count = null;

  // The name of a Type instance.
  //
  // Provided for instance kinds:
  //   Type
  String name = null;

  // The corresponding Class if this Type is canonical.
  //
  // Provided for instance kinds:
  //   Type
  ClassRef typeClass = null;

  // The parameterized class of a type parameter:
  //
  // Provided for instance kinds:
  //   TypeParameter
  ClassRef parameterizedClass = null;

  // The fields of this Instance.
  List<BoundField> fields = null;

  // The elements of a List instance.
  //
  // Provided for instance kinds:
  //   List
  List<Object /*InstanceRef|Sentinel*/ > elements = null;

  // The elements of a Map instance.
  //
  // Provided for instance kinds:
  //   Map
  List<MapAssociation> associations = null;

  // The bytes of a TypedData instance.
  //
  // The data is provided as a Base64 encoded String.
  //
  // Provided for instance kinds:
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  String bytes = null;

  // The function associated with a Closure instance.
  //
  // Provided for instance kinds:
  //   Closure
  FuncRef closureFunction = null;

  // The context associated with a Closure instance.
  //
  // Provided for instance kinds:
  //   Closure
  ContextRef closureContext = null;

  // The referent of a MirrorReference instance.
  //
  // Provided for instance kinds:
  //   MirrorReference
  InstanceRef mirrorReferent = null;

  // The pattern of a RegExp instance.
  //
  // Provided for instance kinds:
  //   RegExp
  String pattern = null;

  // Whether this regular expression is case sensitive.
  //
  // Provided for instance kinds:
  //   RegExp
  bool isCaseSensitive = null;

  // Whether this regular expression matches multiple lines.
  //
  // Provided for instance kinds:
  //   RegExp
  bool isMultiLine = null;

  // The key for a WeakProperty instance.
  //
  // Provided for instance kinds:
  //   WeakProperty
  InstanceRef propertyKey = null;

  // The key for a WeakProperty instance.
  //
  // Provided for instance kinds:
  //   WeakProperty
  InstanceRef propertyValue = null;

  // The type arguments for this type.
  //
  // Provided for instance kinds:
  //   Type
  TypeArgumentsRef typeArguments = null;

  // The index of a TypeParameter instance.
  //
  // Provided for instance kinds:
  //   TypeParameter
  int parameterIndex = null;

  // The type bounded by a BoundedType instance
  // - or -
  // the referent of a TypeRef instance.
  //
  // The value will always be of one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  //
  // Provided for instance kinds:
  //   BoundedType
  //   TypeRef
  InstanceRef targetType = null;

  // The bound of a TypeParameter or BoundedType.
  //
  // The value will always be of one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  //
  // Provided for instance kinds:
  //   BoundedType
  //   TypeParameter
  InstanceRef bound = null;

  InstanceRef toRef() => InstanceRef(id, kind, class_);
}

enum InstanceKind {
  // A general instance of the Dart class Object.
  PlainInstance,

  // null instance.
  Null,

  // true or false.
  Bool,

  // An instance of the Dart class double.
  Double,

  // An instance of the Dart class int.
  Int,

  // An instance of the Dart class String.
  String,

  // An instance of the built-in VM List implementation. User-defined
  // Lists will be PlainInstance.
  List,

  // An instance of the built-in VM Map implementation. User-defined
  // Maps will be PlainInstance.
  Map,

  // Vector instance kinds.
  Float32x4,
  Float64x2,
  Int32x4,

  // An instance of the built-in VM TypedData implementations. User-defined
  // TypedDatas will be PlainInstance.
  Uint8ClampedList,
  Uint8List,
  Uint16List,
  Uint32List,
  Uint64List,
  Int8List,
  Int16List,
  Int32List,
  Int64List,
  Float32List,
  Float64List,
  Int32x4List,
  Float32x4List,
  Float64x2List,

  // An instance of the Dart class StackTrace.
  StackTrace,

  // An instance of the built-in VM Closure implementation. User-defined
  // Closures will be PlainInstance.
  Closure,

  // An instance of the Dart class MirrorReference.
  MirrorReference,

  // An instance of the Dart class RegExp.
  RegExp,

  // An instance of the Dart class WeakProperty.
  WeakProperty,

  // An instance of the Dart class Type.
  Type,

  // An instance of the Dart class TypeParameter.
  TypeParameter,

  // An instance of the Dart class TypeRef.
  TypeRef,

  // An instance of the Dart class BoundedType.
  BoundedType,
}

class IsolateRef extends Response {
  IsolateRef() : super('@Isolate');

  // The id which is passed to the getIsolate RPC to load this isolate.
  String id;

  // A numeric id for this isolate, represented as a String. Unique.
  String number;

  // A name identifying this isolate. Not guaranteed to be unique.
  String name;
}

class Isolate extends Response {
  Isolate() : super('Isolate');

  // The id which is passed to the getIsolate RPC to reload this
  // isolate.
  String id;

  // A numeric id for this isolate, represented as a String. Unique.
  String number;

  // A name identifying this isolate. Not guaranteed to be unique.
  String name;

  // The time that the VM started in milliseconds since the epoch.
  //
  // Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int startTime;

  // Is the isolate in a runnable state?
  bool runnable;

  // The number of live ports for this isolate.
  int livePorts;

  // Will this isolate pause when exiting?
  bool pauseOnExit;

  // The last pause event delivered to the isolate. If the isolate is
  // running, this will be a resume event.
  Event pauseEvent;

  // The root library for this isolate.
  //
  // Guaranteed to be initialized when the IsolateRunnable event fires.
  LibraryRef rootLib = null;

  // A list of all libraries for this isolate.
  //
  // Guaranteed to be initialized when the IsolateRunnable event fires.
  List<LibraryRef> get libraries => _libraries.map((i) => i.toRef()).toList();
  List<Library> _libraries = [];
  List<Library> getLibraries() => _libraries;

  // A list of all breakpoints for this isolate.
  List<Breakpoint> breakpoints;

  // The error that is causing this isolate to exit, if applicable.
  Error error = null;

  // The current pause on exception mode for this isolate.
  ExceptionPauseMode exceptionPauseMode;

  // The list of service extension RPCs that are registered for this isolate,
  // if any.
  List<String> extensionRPCs = null;

  IsolateRef toRef() => IsolateRef()
    ..id = id
    ..number = number
    ..name = name;
}

class LibraryRef extends ObjRef {
  LibraryRef(String id, this.name, this.uri) : super('@Library', id);

  // The name of this library.
  final String name;

  // The uri of this library.
  final String uri;
}

class Library extends Obj {
  Library() : super('Library');

  // The name of this library.
  String name;

  // The uri of this library.
  String uri;

  // Is this library debuggable? Default true.
  bool debuggable = true;

  // A list of the imports for this library.
  List<LibraryDependency> dependencies = [];

  // A list of the scripts which constitute this library.
  List<ScriptRef> get scripts => _scripts.map((i) => i.toRef()).toList();
  List<Script> _scripts = [];
  List<Script> getScripts() => _scripts;

  // A list of the top-level variables in this library.
  List<FieldRef> variables = [];

  // A list of the top-level functions in this library.
  List<FuncRef> functions = [];

  // A list of all classes in this library.
  List<ClassRef> classes = [];

  LibraryRef toRef() => LibraryRef(id, name, uri);
}

class LibraryDependency {
  // Is this dependency an import (rather than an export)?
  bool isImport;

  // Is this dependency deferred?
  bool isDeferred;

  // The prefix of an 'as' import, or null.
  String prefix;

  // The library being imported or exported.
  LibraryRef target;
}

class MapAssociation {
  Object /*InstanceRef|Sentinel*/ key;
  Object /*InstanceRef|Sentinel*/ value;
}

class Message extends Response {
  Message() : super('Message');

  // The index in the isolate's message queue. The 0th message being the next
  // message to be processed.
  int index;

  // An advisory name describing this message.
  String name;

  // An instance id for the decoded message. This id can be passed to other
  // RPCs, for example, getObject or evaluate.
  String messageObjectId;

  // The size (bytes) of the encoded message.
  int size;

  // A reference to the function that will be invoked to handle this message.
  FuncRef handler = null;

  // The source location of handler.
  SourceLocation location = null;
}

class NullRef extends InstanceRef {
  NullRef(String id, InstanceKind kind, ClassRef class_)
      : super(id, kind, class_);

  // Always 'null'.
  String valueAsString = 'null';
}

class Null extends Instance {
  // Always 'null'.
  String valueAsString = 'null';

  NullRef toRef() => NullRef(id, kind, class_);
}

class ObjRef extends Response {
  ObjRef(String type, this.id) : super(type);

  // A unique identifier for an Object. Passed to the
  // getObject RPC to load this Object.
  String id;
}

abstract class Obj extends Response {
  Obj(String type) : super(type);

  // A unique identifier for an Object. Passed to the
  // getObject RPC to reload this Object.
  //
  // Some objects may get a new id when they are reloaded.
  String id;

  // If an object is allocated in the Dart heap, it will have
  // a corresponding class object.
  //
  // The class of a non-instance is not a Dart class, but is instead
  // an internal vm object.
  //
  // Moving an Object into or out of the heap is considered a
  // backwards compatible change for types other than Instance.
  ClassRef class_ = null;

  // The size of this object in the heap.
  //
  // If an object is not heap-allocated, then this field is omitted.
  //
  // Note that the size can be zero for some objects. In the current
  // VM implementation, this occurs for small integers, which are
  // stored entirely within their object pointers.
  int size = null;

  // Return a reference to this object.
  ObjRef toRef();
}

class ReloadReport extends Response {
  ReloadReport() : super('ReloadReport');

  // Did the reload succeed or fail?
  bool success;
}

class Response {
  Response(this.type);

  // Every response returned by the VM Service has the
  // type property. This allows the client distinguish
  // between different kinds of responses.
  String type;
}

class Sentinel extends Response {
  Sentinel() : super('Sentinel');

  // What kind of sentinel is this?
  SentinelKind kind;

  // A reasonable String representation of this sentinel.
  String valueAsString;
}

enum SentinelKind {
  // Indicates that the object referred to has been collected by the GC.
  Collected,

  // Indicates that an object id has expired.
  Expired,

  // Indicates that a variable or field has not been initialized.
  NotInitialized,

  // Indicates that a variable or field is in the process of being initialized.
  BeingInitialized,

  // Indicates that a variable has been eliminated by the optimizing compiler.
  OptimizedOut,

  // Reserved for future use.
  Free,
}

enum FrameKind { Regular, AsyncCausal, AsyncSuspensionMarker, AsyncActivation }

class ScriptRef extends ObjRef {
  ScriptRef(String id, this.uri) : super('@Script', id);

  // The uri from which this script was loaded.
  final String uri;
}

class Script extends Obj {
  Script() : super('Script');

  // The uri from which this script was loaded.
  String uri;

  // The library which owns this script.
  LibraryRef library;

  // The source code for this script. This can be null for certain built-in
  // scripts.
  String source = null;

  // A table encoding a mapping from token position to line and column.
  List<List<int>> tokenPosTable;

  ScriptRef toRef() => ScriptRef(id, uri);
}

class ScriptList extends Response {
  ScriptList() : super('ScriptList');

  List<ScriptRef> scripts;
}

class SourceLocation extends Response {
  SourceLocation() : super('SourceLocation');

  // The script containing the source location.
  ScriptRef script;

  // The first token of the location.
  int tokenPos;

  // The last token of the location if this is a range.
  int endTokenPos = null;
}

class SourceReport extends Response {
  SourceReport() : super('SourceReport');

  // A list of ranges in the program source.  These ranges correspond
  // to ranges of executable code in the user's program (functions,
  // methods, constructors, etc.)
  //
  // Note that ranges may nest in other ranges, in the case of nested
  // functions.
  //
  // Note that ranges may be duplicated, in the case of mixins.
  List<SourceReportRange> ranges;

  // A list of scripts, referenced by index in the report's ranges.
  List<ScriptRef> scripts;
}

class SourceReportCoverage {
  // A list of token positions in a SourceReportRange which have been
  // executed.  The list is sorted.
  List<int> hits;

  // A list of token positions in a SourceReportRange which have not been
  // executed.  The list is sorted.
  List<int> misses;
}

enum SourceReportKind {
  // Used to request a code coverage information.
  Coverage,

  // Used to request a list of token positions of possible breakpoints.
  PossibleBreakpoints
}

class SourceReportRange {
  // An index into the script table of the SourceReport, indicating
  // which script contains this range of code.
  int scriptIndex;

  // The token position at which this range begins.
  int startPos;

  // The token position at which this range ends.  Inclusive.
  int endPos;

  // Has this range been compiled by the Dart VM?
  bool compiled;

  // The error while attempting to compile this range, if this
  // report was generated with forceCompile=true.
  ErrorRef error = null;

  // Code coverage information for this range.  Provided only when the
  // Coverage report has been requested and the range has been
  // compiled.
  SourceReportCoverage coverage = null;

  // Possible breakpoint information for this range, represented as a
  // sorted list of token positions.  Provided only when the when the
  // PossibleBreakpoint report has been requested and the range has been
  // compiled.
  List<int> possibleBreakpoints = null;
}

class Stack extends Response {
  Stack() : super('Stack');

  List<Frame> frames;
  List<Frame> asyncCausalFrames = null;
  List<Frame> awaiterFrames = null;
  List<Message> messages;
}

enum ExceptionPauseMode {
  None,
  Unhandled,
  All,
}

enum StepOption { Into, Over, OverAsyncSuspension, Out, Rewind }

class Success extends Response {
  Success() : super('Success');
}

class TimelineEvent {}

class TypeArgumentsRef extends ObjRef {
  TypeArgumentsRef(String id, this.name) : super('@TypeArguments', id);

  // A name for this type argument list.
  String name;
}

class TypeArguments extends Obj {
  TypeArguments() : super('TypeArguments');

  // A name for this type argument list.
  String name;

  // A list of types.
  //
  // The value will always be one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  List<InstanceRef> types;

  TypeArgumentsRef toRef() => TypeArgumentsRef(id, name);
}

class UnresolvedSourceLocation extends Response {
  UnresolvedSourceLocation() : super('UnresolvedSourceLocation');

  // The script containing the source location if the script has been loaded.
  ScriptRef script = null;

  // The uri of the script containing the source location if the script
  // has yet to be loaded.
  String scriptUri = null;

  // An approximate token position for the source location. This may
  // change when the location is resolved.
  int tokenPos = null;

  // An approximate line number for the source location. This may
  // change when the location is resolved.
  int line = null;

  // An approximate column number for the source location. This may
  // change when the location is resolved.
  int column = null;
}

class Version extends Response {
  Version() : super('Version');

  // The major version number is incremented when the protocol is changed
  // in a potentially incompatible way.
  int major;

  // The minor version number is incremented when the protocol is changed
  // in a backwards compatible way.
  int minor;
}

class VMRef extends Response {
  VMRef() : super('@VM');

  // A name identifying this vm. Not guaranteed to be unique.
  String name;
}

class VM extends Response {
  VM() : super('VM');

  String name = 'Dart Web';

  // Word length on target architecture (e.g. 32, 64).
  int architectureBits;

  // The CPU we are generating code for.
  String targetCPU;

  // The CPU we are actually running on.
  String hostCPU;

  // The Dart VM version String.
  String version;

  // The process id for the VM.
  int pid;

  // The time that the VM started in milliseconds since the epoch.
  //
  // Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int startTime;

  // A list of isolates running in the VM.
  List<IsolateRef> get isolates => _isolates.map((i) => i.toRef()).toList();
  List<Isolate> _isolates = [];
  List<Isolate> getIsolates() => _isolates;
}
