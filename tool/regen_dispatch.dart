// Regenerates icu_kit's dispatch layer.
//
// The dispatch layer is the single point that decides between
// `Class.foo(...)` (compiled-data) and `Class.fooWithProvider(provider, ...)`
// per call. Facades call dispatch methods; they never branch themselves.
//
// Run after every Diplomat regen:
//
//   fvm dart run tool/regen_dispatch.dart
//
// Outputs:
//   lib/src/runtime/native/dispatch.g.dart   (FFI-typed twin)
//   lib/src/runtime/web/dispatch.g.dart       (mirror-typed twin)
//
// The generator pairs `*WithProvider` / `*AndProvider` factories in the
// Diplomat-generated FFI bindings with their compiled-data counterparts,
// then emits a dispatch method per pair. Web emission inspects the
// matching `web_assets/lib/X.mjs` files to learn the JS-side name mapping
// (which is NOT a simple `create<X>` rule — Diplomat picks names per
// method).
//
// Idempotent: rerunning produces byte-identical output.

import 'dart:io';

const _bindingsDir = 'lib/src/runtime/native/bindings';
const _webJsDir = 'web_assets/lib';
const _nativeOut = 'lib/src/runtime/native/dispatch.g.dart';
const _webOut = 'lib/src/runtime/web/dispatch.g.dart';

void main() {
  final pkgRoot = Directory.current;
  final bindings = Directory('${pkgRoot.path}/$_bindingsDir');
  if (!bindings.existsSync()) {
    stderr.writeln('ERROR: $_bindingsDir not found. Run from icu_kit root.');
    exit(1);
  }
  final webJs = Directory('${pkgRoot.path}/$_webJsDir');
  if (!webJs.existsSync()) {
    stderr.writeln(
      'ERROR: $_webJsDir not found. Build wasm first via tool/build_wasm.dart.',
    );
    exit(1);
  }

  // Collect all factory pairs.
  final pairs = <_Pair>[];
  for (final entity in bindings.listSync()) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.g.dart')) continue;
    final name = entity.path.split('/').last;
    if (name == 'lib.g.dart') continue;
    final className = name.substring(0, name.length - '.g.dart'.length);
    final source = entity.readAsStringSync();

    // Read parallel JS module if present.
    final jsFile = File('${webJs.path}/$className.mjs');
    final jsSource = jsFile.existsSync() ? jsFile.readAsStringSync() : '';

    pairs.addAll(_extractPairs(className, source, jsSource));
  }

  pairs.sort((a, b) {
    final c = a.className.compareTo(b.className);
    if (c != 0) return c;
    return a.dispatchName.compareTo(b.dispatchName);
  });

  // Emit only the dispatch methods some facade actually calls (mirror
  // Rule 3 — used surface only). The scan finds `dispatch.<name>(` across
  // lib/src, excluding the two generated outputs themselves. A new facade
  // that calls a new dispatch method: write the call, rerun this tool.
  final used = _scanUsedDispatchNames(Directory('${pkgRoot.path}/lib/src'));
  final skipped = pairs.where((p) => !used.contains(p.dispatchName)).length;
  pairs.retainWhere((p) => used.contains(p.dispatchName));

  final enums = _scanEnumNames(bindings);

  File(_nativeOut).writeAsStringSync(_emitNative(pairs));
  File(_webOut).writeAsStringSync(_emitWeb(pairs, enums));

  // Format the outputs with the running SDK so regen is byte-idempotent
  // and never trips the repo's format gate.
  Process.runSync(Platform.resolvedExecutable, ['format', _nativeOut, _webOut]);

  print('Skipped $skipped unused pairs.');
  print('Wrote ${pairs.length} dispatch methods:');
  print('  $_nativeOut');
  print('  $_webOut');

  final classes = pairs.map((p) => p.className).toSet().toList()..sort();
  print('Covers ${classes.length} binding classes:');
  for (final c in classes) {
    final n = pairs.where((p) => p.className == c).length;
    print('  $c ($n method${n == 1 ? '' : 's'})');
  }
}

/// Every `dispatch.<name>(` call site under lib/src (facades, data layer),
/// excluding the generated outputs themselves.
Set<String> _scanUsedDispatchNames(Directory libSrc) {
  final used = <String>{};
  final re = RegExp(r'dispatch\.(\w+)\s*\(');
  for (final f in libSrc.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    if (f.path.endsWith('dispatch.g.dart')) continue;
    for (final m in re.allMatches(f.readAsStringSync())) {
      used.add(m.group(1)!);
    }
  }
  return used;
}

/// Names of all `enum X` declarations in the FFI bindings — used by the
/// web emitter to decide which params need a `.toJs()` conversion.
Set<String> _scanEnumNames(Directory bindings) {
  final out = <String>{};
  final re = RegExp(r'^enum (\w+)', multiLine: true);
  for (final f in bindings.listSync().whereType<File>()) {
    if (!f.path.endsWith('.g.dart')) continue;
    for (final m in re.allMatches(f.readAsStringSync())) {
      out.add(m.group(1)!);
    }
  }
  return out;
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _Pair {
  // JS method name

  _Pair({
    required this.className,
    required this.dispatchName,
    required this.compiled,
    required this.provider,
    required this.jsCompiledName,
    required this.jsProviderName,
  });
  final String className; // 'PluralRules'
  final String dispatchName; // 'pluralRulesCardinal'
  final _Factory compiled; // Dart compiled-data factory
  final _Factory provider; // Dart *WithProvider factory
  final String? jsCompiledName; // JS method name (null = default-ctor)
  final String? jsProviderName;
}

class _Factory {
  _Factory({required this.methodName, required this.params});
  final String? methodName; // null = default constructor
  final List<_Param> params;

  bool get isDefaultCtor => methodName == null;
}

class _Param {
  _Param({
    required this.type,
    required this.name,
    required this.named,
    required this.optional,
    this.defaultValue,
  });
  final String type;
  final String name;
  final bool named;
  final bool optional;
  final String? defaultValue;

  bool get isProvider => type == 'DataProvider' && name == 'provider';
}

// ─────────────────────────────────────────────────────────────────────────────
// Parsing
// ─────────────────────────────────────────────────────────────────────────────

List<_Pair> _extractPairs(
  String className,
  String dartSource,
  String jsSource,
) {
  final factories = _parseDartFactories(className, dartSource);
  final jsMethods = _parseJsStaticMethods(jsSource);

  final pairs = <_Pair>[];
  for (final entry in factories.entries) {
    final method = entry.key;
    final providerFactory = entry.value;

    if (method == '_default') {
      continue; // default ctor never has WithProvider form
    }
    // Detect provider variants:
    //  - `withProvider` (default-ctor pair, e.g. TimeFormatter.withProvider)
    //  - `<base>WithProvider` (named-factory pair, e.g. PluralRules.cardinalWithProvider)
    //  - `<base>AndProvider` (named-with-suffix factory pair, e.g. ListFormatter.andWithLengthAndProvider)
    final isLowerWithProvider = method == 'withProvider';
    final isWithProvider =
        method.endsWith('WithProvider') && method != 'WithProvider';
    final isAndProvider = method.endsWith('AndProvider');
    if (!isLowerWithProvider && !isWithProvider && !isAndProvider) {
      continue;
    }

    String? compiledMethod;
    if (isLowerWithProvider) {
      // Pairs with default constructor.
      if (factories.containsKey('_default')) compiledMethod = '_default';
    } else if (isAndProvider) {
      final base = method.substring(0, method.length - 'AndProvider'.length);
      if (factories.containsKey(base)) compiledMethod = base;
    } else if (isWithProvider) {
      final base = method.substring(0, method.length - 'WithProvider'.length);
      if (base.isNotEmpty && factories.containsKey(base)) {
        compiledMethod = base;
      } else if ((base.isEmpty || base == 'new' || base == 'create') &&
          factories.containsKey('_default')) {
        // `newWithProvider` (Calendar) / `createWithProvider` (Collator)
        // pair with the default ctor.
        compiledMethod = '_default';
      }
    }
    if (compiledMethod == null) {
      stderr.writeln('skip $className.$method: no compiled-data pair found');
      continue;
    }

    final compiled = factories[compiledMethod]!;
    final dispatchName = _toDispatchName(className, method);

    // Look up JS-side names if we have the JS module. We pair by signature
    // (param count). Compiled JS method has the same param count as Dart
    // compiled (no provider); WithProvider JS method has one extra arg.
    String? jsCompiledName;
    String? jsProviderName;
    if (jsSource.isNotEmpty) {
      jsCompiledName = _findJsCounterpart(
        jsMethods,
        compiledMethod,
        compiled.params.length,
      );
      jsProviderName = _findJsCounterpart(
        jsMethods,
        method,
        providerFactory.params.length,
      );
    }

    pairs.add(
      _Pair(
        className: className,
        dispatchName: dispatchName,
        compiled: _Factory(
          methodName: compiled.isDefaultCtor ? null : compiled.methodName,
          params: compiled.params,
        ),
        provider: providerFactory,
        jsCompiledName: jsCompiledName,
        jsProviderName: jsProviderName,
      ),
    );
  }
  return pairs;
}

/// Parse all `factory ClassName(...)` and `factory ClassName.method(...)`
/// declarations. Returns map: method name → factory. Default ctor uses key
/// `_default`.
Map<String, _Factory> _parseDartFactories(String className, String source) {
  final out = <String, _Factory>{};
  final regex = RegExp(
    r'factory\s+' +
        RegExp.escape(className) +
        r'(?:\.(\w+))?\s*\(([^)]*)\)\s*\{',
    multiLine: true,
  );
  for (final m in regex.allMatches(source)) {
    final method = m.group(1) ?? '_default';
    final paramsRaw = m.group(2) ?? '';
    out[method] = _Factory(
      methodName: method == '_default' ? null : method,
      params: _parseParams(paramsRaw),
    );
  }
  return out;
}

/// Parse `static methodName(arg1, arg2, ...) {` declarations from a JS
/// module file. Returns map: methodName → arg count.
Map<String, int> _parseJsStaticMethods(String source) {
  final out = <String, int>{};
  final regex = RegExp(r'^\s*static\s+(\w+)\(([^)]*)\)\s*\{', multiLine: true);
  for (final m in regex.allMatches(source)) {
    final method = m.group(1)!;
    final argsRaw = m.group(2) ?? '';
    final argCount = argsRaw.trim().isEmpty ? 0 : argsRaw.split(',').length;
    out[method] = argCount;
  }
  return out;
}

/// Find the JS method name that corresponds to a Dart factory. Pairs by
/// (camelCase of dart name) and arg count.
///
/// Strategy:
///   1. Build candidates: `dartMethod` (verbatim), `create<DartMethod>` (Pascal).
///   2. Pick the one whose JS signature has matching arg count.
///
/// For default ctor (`_default`), JS doesn't have a `static`; web facade
/// uses `callAsConstructor`. Returns null in that case.
String? _findJsCounterpart(
  Map<String, int> jsMethods,
  String dartMethod,
  int dartArgCount,
) {
  if (dartMethod == '_default') return null;

  final candidates = <String>[
    dartMethod,
    'create${dartMethod[0].toUpperCase()}${dartMethod.substring(1)}',
  ];
  for (final name in candidates) {
    final jsArgCount = jsMethods[name];
    if (jsArgCount == null) continue;
    if (jsArgCount == dartArgCount) return name;
  }
  // No exact match. Try by name only (arg count may differ for optional
  // params which JS sometimes elides).
  for (final name in candidates) {
    if (jsMethods.containsKey(name)) return name;
  }
  return null;
}

List<_Param> _parseParams(String raw) {
  final params = <_Param>[];
  if (raw.trim().isEmpty) return params;

  String positionalSeg = raw;
  String namedSeg = '';
  String optPosSeg = '';

  final namedStart = raw.indexOf('{');
  final namedEnd = raw.lastIndexOf('}');
  final optStart = raw.indexOf('[');
  final optEnd = raw.lastIndexOf(']');

  if (namedStart >= 0 && namedEnd > namedStart) {
    namedSeg = raw.substring(namedStart + 1, namedEnd);
    positionalSeg = raw.substring(0, namedStart).trim();
    if (positionalSeg.endsWith(',')) {
      positionalSeg = positionalSeg
          .substring(0, positionalSeg.length - 1)
          .trim();
    }
  } else if (optStart >= 0 && optEnd > optStart) {
    optPosSeg = raw.substring(optStart + 1, optEnd);
    positionalSeg = raw.substring(0, optStart).trim();
    if (positionalSeg.endsWith(',')) {
      positionalSeg = positionalSeg
          .substring(0, positionalSeg.length - 1)
          .trim();
    }
  }

  for (final tok in _splitTopLevel(positionalSeg)) {
    final p = _parseSingleParam(tok, named: false, optional: false);
    if (p != null) params.add(p);
  }
  for (final tok in _splitTopLevel(optPosSeg)) {
    final p = _parseSingleParam(tok, named: false, optional: true);
    if (p != null) params.add(p);
  }
  for (final tok in _splitTopLevel(namedSeg)) {
    final p = _parseSingleParam(tok, named: true, optional: true);
    if (p != null) params.add(p);
  }
  return params;
}

List<String> _splitTopLevel(String raw) {
  if (raw.trim().isEmpty) return const [];
  final tokens = <String>[];
  var depth = 0;
  var buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final c = raw[i];
    if (c == '<' || c == '[' || c == '{') depth++;
    if (c == '>' || c == ']' || c == '}') depth--;
    if (c == ',' && depth == 0) {
      tokens.add(buf.toString().trim());
      buf = StringBuffer();
      continue;
    }
    buf.write(c);
  }
  if (buf.isNotEmpty) tokens.add(buf.toString().trim());
  return tokens.where((t) => t.isNotEmpty).toList();
}

_Param? _parseSingleParam(
  String raw, {
  required bool named,
  required bool optional,
}) {
  if (raw.isEmpty) return null;
  var t = raw;
  String? defaultValue;
  final eqIdx = t.indexOf('=');
  if (eqIdx >= 0) {
    defaultValue = t.substring(eqIdx + 1).trim();
    t = t.substring(0, eqIdx).trim();
  }
  if (t.startsWith('required ')) {
    t = t.substring('required '.length).trim();
  }
  final lastSpace = t.lastIndexOf(' ');
  if (lastSpace < 0) return null;
  final type = t.substring(0, lastSpace).trim();
  final name = t.substring(lastSpace + 1).trim();
  return _Param(
    type: type,
    name: name,
    named: named,
    optional: optional,
    defaultValue: defaultValue,
  );
}

String _toDispatchName(String className, String providerMethod) {
  final lcClass = className[0].toLowerCase() + className.substring(1);

  String base;
  if (providerMethod == 'withProvider') {
    base = '';
  } else if (providerMethod.endsWith('AndProvider')) {
    base = providerMethod.substring(
      0,
      providerMethod.length - 'AndProvider'.length,
    );
  } else if (providerMethod.endsWith('WithProvider')) {
    base = providerMethod.substring(
      0,
      providerMethod.length - 'WithProvider'.length,
    );
  } else {
    base = providerMethod;
  }

  if (base.isEmpty || base == 'new' || base == 'create') {
    return '${lcClass}Default';
  }
  final cap = base[0].toUpperCase() + base.substring(1);
  return '$lcClass$cap';
}

// ─────────────────────────────────────────────────────────────────────────────
// Native emission
// ─────────────────────────────────────────────────────────────────────────────

String _emitNative(List<_Pair> pairs) {
  final buf = StringBuffer();
  buf.write(_nativeHeader);
  for (final p in pairs) {
    buf.write(_emitNativeMethod(p));
    buf.writeln();
  }
  return buf.toString();
}

const _nativeHeader = '''
// AUTO-GENERATED — DO NOT EDIT
//
// Run `fvm dart run tool/regen_dispatch.dart` to regenerate.
//
// One method per `Class.fooWithProvider` constructor exposed by the
// Diplomat-generated FFI bindings. Each method dispatches between the
// compiled-data form and the `*WithProvider` form based on the active
// `IcuData` (see `IcuKit.init`).
//
// Facades call these dispatch methods instead of branching themselves.

import 'bindings.dart' as icu;
import 'init.dart';

''';

String _emitNativeMethod(_Pair p) {
  final hasLocale = p.compiled.params.any((x) => x.type == 'Locale');
  final paramSig = _nativeParamSig(p.compiled.params);
  final lookup = hasLocale
      ? 'IcuKit.providerFor(localeStr)'
      : "IcuKit.providerFor('und')";

  final compiledArgs = _nativeArgList(
    factory: p.compiled,
    isProviderForm: false,
    matchSig: p.compiled.params,
  );
  final providerArgs = _nativeArgList(
    factory: p.provider,
    isProviderForm: true,
    matchSig: p.compiled.params,
  );

  final compiledRef = p.compiled.isDefaultCtor
      ? 'icu.${p.className}'
      : 'icu.${p.className}.${p.compiled.methodName}';
  final providerRef = 'icu.${p.className}.${p.provider.methodName}';

  final buf = StringBuffer();
  buf.writeln('icu.${p.className} ${p.dispatchName}($paramSig) {');
  buf.writeln('  final p = $lookup;');
  buf.writeln('  return p == null');
  buf.writeln('      ? $compiledRef($compiledArgs)');
  buf.writeln('      : $providerRef($providerArgs);');
  buf.writeln('}');
  return buf.toString();
}

String _nativeParamSig(List<_Param> compiledParams) {
  final positionalRequired = <_Param>[];
  final positionalOptional = <_Param>[];
  final named = <_Param>[];
  for (final p in compiledParams) {
    if (p.named) {
      named.add(p);
    } else if (p.optional) {
      positionalOptional.add(p);
    } else {
      positionalRequired.add(p);
    }
  }

  final hasLocale = compiledParams.any((p) => p.type == 'Locale');

  final segs = <String>[];
  if (hasLocale) segs.add('String localeStr');
  for (final p in positionalRequired) {
    segs.add('${_typeForNative(p.type)} ${p.name}');
  }
  if (positionalOptional.isNotEmpty) {
    final inner = positionalOptional
        .map(
          (p) =>
              '${_typeForNative(p.type)} ${p.name}'
              '${p.defaultValue != null ? ' = ${p.defaultValue}' : ''}',
        )
        .join(', ');
    segs.add('[$inner]');
  }
  if (named.isNotEmpty) {
    final inner = named
        .map((p) {
          final type = _typeForNative(p.type);
          final isNullable = p.type.endsWith('?') || p.defaultValue != null;
          final req = !isNullable ? 'required ' : '';
          final def = p.defaultValue != null ? ' = ${p.defaultValue}' : '';
          return '$req$type ${p.name}$def';
        })
        .join(', ');
    segs.add('{$inner}');
  }
  return segs.join(', ');
}

String _typeForNative(String bindingType) {
  const primitives = {
    'int',
    'bool',
    'String',
    'double',
    'num',
    'Object',
    'void',
  };
  final clean = bindingType.endsWith('?')
      ? bindingType.substring(0, bindingType.length - 1)
      : bindingType;
  if (primitives.contains(clean)) return bindingType;
  return 'icu.$bindingType';
}

/// Build the arg list for a call to `factory`. Each compiled-side param
/// is either passed verbatim, OR (in the WithProvider branch) prefixed
/// with `p` for the provider arg. If types differ between compiled and
/// provider (rare), insert a cast.
String _nativeArgList({
  required _Factory factory,
  required bool isProviderForm,
  required List<_Param> matchSig,
}) {
  final positional = <String>[];
  final named = <String>[];
  for (final p in factory.params) {
    if (isProviderForm && p.isProvider) {
      positional.add('p');
      continue;
    }
    // In WithProvider form, pull the value from a same-named param in
    // the dispatch signature (which uses compiled types). Cast if types
    // differ.
    final matched = matchSig.firstWhere(
      (s) => s.name == p.name,
      orElse: () => p,
    );
    final needsCast = matched.type != p.type && !p.isProvider;
    final raw = needsCast
        ? _castExpression(matched.type, p.type, p.name)
        : p.name;
    if (p.named) {
      named.add('${p.name}: $raw');
    } else {
      positional.add(raw);
    }
  }
  if (named.isNotEmpty) positional.add(named.join(', '));
  return positional.join(', ');
}

/// Build a cast expression from one Dart type to another. The known
/// case in ICU4X 2.2 is `GeneralCategoryGroup` (typed enum) → `int`
/// (raw mask) for `CodePointSetData.generalCategoryGroupWithProvider`.
/// For unknown mismatches, fall back to a stark `as` cast and let the
/// analyzer flag it.
String _castExpression(String fromType, String toType, String varName) {
  // Specific: typed enum → int via .ffiValue (Diplomat exposes this).
  if (toType == 'int' &&
      (fromType == 'GeneralCategoryGroup' ||
          fromType.endsWith('Kind') ||
          fromType.endsWith('Group'))) {
    return '$varName.mask';
  }
  // Generic fallback.
  return '$varName as $toType';
}

// ─────────────────────────────────────────────────────────────────────────────
// Web emission
// ─────────────────────────────────────────────────────────────────────────────

String _emitWeb(List<_Pair> pairs, Set<String> enums) {
  final buf = StringBuffer();
  buf.write(_webHeader);
  for (final p in pairs) {
    buf.write(_emitWebMethod(p, enums));
    buf.writeln();
  }
  return buf.toString();
}

const _webHeader = '''
// AUTO-GENERATED — DO NOT EDIT
//
// Run `fvm dart run tool/regen_dispatch.dart` to regenerate.
//
// Web twin of `../native/dispatch.g.dart` — SAME Dart signatures, typed
// against the js_interop mirrors, so facades compile against either
// resolution of `../dispatch.dart` unchanged. Each method calls the
// corresponding JS Diplomat binding; JS method names are extracted from
// `web_assets/lib/<Class>.mjs` at generation time, so naming exceptions
// (e.g. a `create` prefix on some statics and not others) are handled
// automatically.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'bindings.dart' as icu;
import 'init.dart';

''';

String _emitWebMethod(_Pair p, Set<String> enums) {
  final hasLocale = p.compiled.params.any((x) => x.type == 'Locale');
  final paramSig = _nativeParamSig(p.compiled.params);
  final lookup = hasLocale
      ? 'IcuKit.providerFor(localeStr)'
      : "IcuKit.providerFor('und')";

  // Convert a dispatch-signature param (mirror-typed) to the JSAny? the
  // JS call needs: primitives via .toJS, binding enums via the mirror's
  // .toJs(), opaques/structs pass through (mirrors implement JSObject).
  String conv(_Param x) {
    final t = x.type;
    final nullable = t.endsWith('?');
    final base = nullable ? t.substring(0, t.length - 1) : t;
    const prims = {'int', 'bool', 'String', 'double', 'num'};
    final op = nullable ? '?.' : '.';
    if (prims.contains(base)) return '${x.name}${op}toJS';
    if (enums.contains(base)) return '${x.name}${op}toJs()';
    return x.name;
  }

  final wrap = 'icu.${p.className}.fromDispatch';

  final buf = StringBuffer();
  buf.writeln('icu.${p.className} ${p.dispatchName}($paramSig) {');
  buf.writeln(
    "  final cls = IcuKit.module.getProperty<JSObject>('${p.className}'.toJS);",
  );
  buf.writeln('  final p = $lookup;');

  // Compiled-data arm.
  if (p.compiled.isDefaultCtor) {
    final args = p.compiled.params.map(conv).join(', ');
    buf.writeln('  if (p == null) {');
    buf.writeln(
      "    final fn = IcuKit.module.getProperty<JSFunction>('${p.className}'.toJS);",
    );
    buf.writeln('    return $wrap(fn.callAsConstructor<JSObject>($args));');
    buf.writeln('  }');
  } else {
    final compiledJsName = p.jsCompiledName ?? p.compiled.methodName!;
    final args = p.compiled.params.map(conv).toList();
    buf.writeln('  if (p == null) {');
    buf.writeln(
      '    return $wrap(${_webCallExpr('cls', compiledJsName, args)});',
    );
    buf.writeln('  }');
  }

  // WithProvider arm.
  final providerJsName = p.jsProviderName ?? p.provider.methodName!;
  final providerArgs = <String>['p'];
  for (final pp in p.provider.params) {
    if (pp.isProvider) continue;
    providerArgs.add(conv(pp));
  }
  buf.writeln(
    '  return $wrap(${_webCallExpr('cls', providerJsName, providerArgs)});',
  );

  buf.writeln('}');
  return buf.toString();
}

/// A JS call expression: `cls.callMethod<JSObject>('jsName'.toJS, a, b)`.
/// For >4 args, `callMethodVarArgs`.
String _webCallExpr(String receiver, String jsName, List<String> argExprs) {
  final argsExpr = argExprs.join(', ');
  if (argExprs.length <= 4) {
    return "$receiver.callMethod<JSObject>('$jsName'.toJS${argExprs.isEmpty ? '' : ', $argsExpr'})";
  }
  return "$receiver.callMethodVarArgs<JSObject>('$jsName'.toJS, [$argsExpr])";
}
