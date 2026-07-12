// §3e — dates, times, zones. Over Intl.DateTimeFormat.
//
// Formatting a date in a non-Gregorian calendar works: the locale tag flows
// through unchanged, and Intl.DateTimeFormat honors -u-ca- / -u-nu- / -u-hc-.
// Only the Calendar / Date ARITHMETIC object (field access: leap month,
// day-of-year, rataDie, …) stays throw-all — the browser has no calendar math
// (needs Temporal), and a partial Temporal calendar-id mapping would risk
// WRONG dates (some icu4x hijri variants have no Temporal id). The engine
// surfaces that object as IcuUnsupportedError rather than guess.
// See PLAN_BROWSER_INTL.md §3e + the capability roadmap.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '_util.dart';

// ── Opaque value holders (IsoDate / Time / TimeZone / UtcOffset) ──────────

// IsoDate(year, month, day) → {year, month, dayOfMonth}. The binding reads
// those three props back.
JSObject _isoDate(int year, int month, int day) => JSObject()
  ..setProperty('year'.toJS, year.toJS)
  ..setProperty('month'.toJS, month.toJS)
  ..setProperty('dayOfMonth'.toJS, day.toJS);

// Time(hour, minute, second, subsecond-nanos) → the four fields.
JSObject _time(int hour, int minute, int second, int subsecond) => JSObject()
  ..setProperty('hour'.toJS, hour.toJS)
  ..setProperty('minute'.toJS, minute.toJS)
  ..setProperty('second'.toJS, second.toJS)
  ..setProperty('subsecond'.toJS, subsecond.toJS);

int _num(JSObject o, String k) => o.getProperty<JSNumber>(k.toJS).toDartInt;

// A JS UTC Date built from an IsoDate (+ optional Time). icu4x treats the
// input as wall-clock; we format every own-formatter with timeZone:'UTC' so
// no local-zone shift leaks in.
JSObject _utcDate(JSObject iso, [JSObject? time]) {
  final dateCls = globalContext.getProperty<JSFunction>('Date'.toJS);
  final ms = dateCls.callMethodVarArgs<JSNumber>('UTC'.toJS, [
    _num(iso, 'year').toJS,
    (_num(iso, 'month') - 1).toJS, // JS months are 0-based
    _num(iso, 'dayOfMonth').toJS,
    (time == null ? 0 : _num(time, 'hour')).toJS,
    (time == null ? 0 : _num(time, 'minute')).toJS,
    (time == null ? 0 : _num(time, 'second')).toJS,
    (time == null ? 0 : _num(time, 'subsecond') ~/ 1000000).toJS,
  ]);
  return dateCls.callAsConstructorVarArgs<JSObject>([ms]);
}

// ── Field-set + length → Intl.DateTimeFormat options ─────────────────────

String _len(JSObject? length) =>
    length == null ? 'Medium' : enumStringValue(length);

// Date fields present in a marker: 'y' → year, 'm' → month, 'd' → day,
// 'e' → weekday. Length picks the verbosity per field.
Map<String, JSAny?> _dateFields(String set, JSObject? length, JSObject? year) {
  final l = _len(length);
  final o = <String, JSAny?>{};
  if (set.contains('y')) {
    o['year'] = (l == 'Short' ? '2-digit' : 'numeric').toJS;
    // yearStyle WithEra → surface the era.
    if (year != null && enumStringValue(year) == 'WithEra') {
      o['era'] = 'short'.toJS;
    }
  }
  if (set.contains('m')) {
    o['month'] = switch (l) {
      'Long' => 'long'.toJS,
      'Short' => 'numeric'.toJS,
      _ => 'short'.toJS,
    };
  }
  if (set.contains('d')) o['day'] = 'numeric'.toJS;
  if (set.contains('e')) {
    o['weekday'] = (l == 'Long' ? 'long' : 'short').toJS;
  }
  return o;
}

// TimePrecision → hour/minute/second (+ fractional digits).
Map<String, JSAny?> _timeFields(JSObject? precision) {
  final p = precision == null ? 'Minute' : enumStringValue(precision);
  final o = <String, JSAny?>{'hour': 'numeric'.toJS};
  if (p != 'Hour') o['minute'] = 'numeric'.toJS;
  if (p == 'Second' || p.startsWith('Subsecond')) o['second'] = 'numeric'.toJS;
  if (p.startsWith('Subsecond')) {
    o['fractionalSecondDigits'] = int.parse(
      p.substring('Subsecond'.length),
    ).toJS;
  }
  return o;
}

// A formatter object carries its locale tag + the field options (WITHOUT a
// timeZone — own formatters add UTC; the zoned wrapper adds the real zone).
JSObject _formatter(String tag, Map<String, JSAny?> fields) {
  final o = JSObject()
    ..setProperty('tag'.toJS, tag.toJS)
    ..setProperty('fields'.toJS, jsOptions(fields));
  return o;
}

String _fmtOwn(JSObject self, JSObject jsDate) {
  final tag = self.getProperty<JSString>('tag'.toJS).toDart;
  final fields = self.getProperty<JSObject>('fields'.toJS);
  final opts = _cloneWith(fields, {'timeZone': 'UTC'.toJS});
  return intlFormat(
    'DateTimeFormat',
    tag,
    opts,
  ).callMethod<JSString>('format'.toJS, jsDate).toDart;
}

// Shallow-clone an options object and set extra keys (Object.assign).
JSObject _cloneWith(JSObject base, Map<String, JSAny?> extra) {
  final obj = globalContext.getProperty<JSObject>('Object'.toJS);
  final out = JSObject();
  obj.callMethodVarArgs<JSObject>('assign'.toJS, [out, base]);
  extra.forEach((k, v) => out.setProperty(k.toJS, v));
  return out;
}

// ── Date / Time / DateTime formatters ────────────────────────────────────

JSObject _dateFormatter(
  String set,
  JSObject locale,
  JSObject? length,
  JSObject? alignment,
  JSObject? year,
) {
  final o = _formatter(localeTag(locale), _dateFields(set, length, year));
  String formatIso(JSObject iso) => _fmtOwn(o, _utcDate(iso));
  o.setProperty('formatIso'.toJS, formatIso.toJS);
  return o;
}

JSObject _timeFormatter(
  JSObject locale,
  JSObject? length,
  JSObject? precision,
  JSObject? alignment,
) {
  final o = _formatter(localeTag(locale), _timeFields(precision));
  String format(JSObject time) =>
      _fmtOwn(o, _utcDate(_isoDate(1970, 1, 1), time));
  o.setProperty('format'.toJS, format.toJS);
  return o;
}

JSObject _dateTimeFormatter(
  String set,
  JSObject locale,
  JSObject? length,
  JSObject? precision,
  JSObject? alignment,
  JSObject? year,
) {
  final fields = {..._dateFields(set, length, year), ..._timeFields(precision)};
  final o = _formatter(localeTag(locale), fields);
  String formatIso(JSObject iso, JSObject time) =>
      _fmtOwn(o, _utcDate(iso, time));
  o.setProperty('formatIso'.toJS, formatIso.toJS);
  return o;
}

// ── Zones ────────────────────────────────────────────────────────────────

// Zone style sentinel → Intl timeZoneName. location / exemplarCity THROW.
String _zoneStyle(String create) => switch (create) {
  'SpecificLong' => 'long',
  'SpecificShort' => 'short',
  'GenericLong' => 'longGeneric',
  'GenericShort' => 'shortGeneric',
  'LocalizedOffsetLong' => 'longOffset',
  'LocalizedOffsetShort' => 'shortOffset',
  _ => unsupported('IcuTimeZoneFormat $create (location/exemplarCity)'),
};

JSObject _timeZone(String ianaId) {
  final zoneInfo = JSObject()..setProperty('ianaId'.toJS, ianaId.toJS);
  // atDateTimeIso pins the info to an instant; the id is all Intl needs.
  JSObject at(JSObject iso, JSObject time) => zoneInfo;
  zoneInfo.setProperty('atDateTimeIso'.toJS, at.toJS);

  final tz = JSObject()..setProperty('ianaId'.toJS, ianaId.toJS);
  JSObject withOffset(JSObject offset) => zoneInfo;
  tz.setProperty('withOffset'.toJS, withOffset.toJS);
  return tz;
}

String _zoneId(JSObject zoneInfo) =>
    zoneInfo.getProperty<JSString>('ianaId'.toJS).toDart;

// A reference instant for extracting a zone's name (mid-January noon UTC).
JSObject _zoneRefInstant() =>
    _utcDate(_isoDate(2024, 1, 15), _time(12, 0, 0, 0));

JSObject _timeZoneFormatter(String tag, String create) {
  final style = _zoneStyle(create); // may THROW for location/exemplarCity
  final o = JSObject();
  String format(JSObject zoneInfo) {
    final fmt = intlFormat(
      'DateTimeFormat',
      tag,
      jsOptions({
        'timeZone': _zoneId(zoneInfo).toJS,
        'timeZoneName': style.toJS,
      }),
    );
    final parts = fmt.callMethod<JSArray<JSObject>>(
      'formatToParts'.toJS,
      _zoneRefInstant(),
    );
    for (final p in parts.toDart) {
      if (p.getProperty<JSString>('type'.toJS).toDart == 'timeZoneName') {
        return p.getProperty<JSString>('value'.toJS).toDart;
      }
    }
    // Unreachable for the offset/generic styles that reach here — each yields
    // a timeZoneName part. Do NOT fall back to the raw IANA id: ICU4X never
    // emits it, so leaking it would diverge from the native engine.
    return '';
  }

  o.setProperty('format'.toJS, format.toJS);
  return o;
}

JSObject _zonedDateTimeFormatter(
  String tag,
  String create,
  JSObject formatter,
) {
  final style = _zoneStyle(create); // may THROW for location/exemplarCity
  final fields = formatter.getProperty<JSObject>('fields'.toJS);
  final o = JSObject();
  String formatIso(JSObject iso, JSObject time, JSObject zoneInfo) {
    final opts = _cloneWith(fields, {
      'timeZone': _zoneId(zoneInfo).toJS,
      'timeZoneName': style.toJS,
    });
    return intlFormat(
      'DateTimeFormat',
      tag,
      opts,
    ).callMethod<JSString>('format'.toJS, _utcDate(iso, time)).toDart;
  }

  o.setProperty('formatIso'.toJS, formatIso.toJS);
  return o;
}

/// Register §3e, overriding throw-all defaults. Calendar / Date / CalendarKind
/// stay throw-all (non-ISO calendars are a documented browser-engine gap).
void registerDatetime(JSObject module) {
  // Enums the binding resolves via `module.getProperty('X')`.
  put(module, 'DateTimeLength', enumClass(const ['Long', 'Medium', 'Short']));
  put(module, 'DateTimeAlignment', enumClass(const ['Auto', 'Column']));
  put(
    module,
    'YearStyle',
    enumClass(const ['Auto', 'Full', 'WithEra', 'NoEra']),
  );
  put(
    module,
    'TimePrecision',
    enumClass(const [
      'Hour', 'Minute', 'MinuteOptional', 'Second', //
      'Subsecond1', 'Subsecond2', 'Subsecond3', 'Subsecond4', 'Subsecond5',
      'Subsecond6', 'Subsecond7', 'Subsecond8', 'Subsecond9',
    ]),
  );

  // IsoDate(y,m,d) / Time(h,m,s,ns) — plain-ctor value holders.
  put(
    module,
    'IsoDate',
    ctorClass(
      ((JSNumber y, JSNumber m, JSNumber d) => _isoDate(
        y.toDartInt,
        m.toDartInt,
        d.toDartInt,
      )).toJS,
    ),
  );
  put(
    module,
    'Time',
    ctorClass(
      ((JSNumber h, JSNumber m, JSNumber s, JSNumber ns) => _time(
        h.toDartInt,
        m.toDartInt,
        s.toDartInt,
        ns.toDartInt,
      )).toJS,
    ),
  );

  // DateFormatter — 10 field-set statics, each (locale, [len, align, year]).
  put(
    module,
    'DateFormatter',
    staticClass({
      for (final e in const {
        'createD': 'd',
        'createDe': 'de',
        'createE': 'e',
        'createM': 'm',
        'createMd': 'md',
        'createMde': 'mde',
        'createY': 'y',
        'createYm': 'ym',
        'createYmd': 'ymd',
        'createYmde': 'ymde',
      }.entries)
        e.key:
            ((JSObject l, [JSObject? len, JSObject? align, JSObject? year]) =>
                    _dateFormatter(e.value, l, len, align, year))
                .toJS,
    }),
  );

  // TimeFormatter — a plain ctor (locale, [len, precision, align]).
  put(
    module,
    'TimeFormatter',
    ctorClass(
      ((JSObject l, [JSObject? len, JSObject? prec, JSObject? align]) =>
              _timeFormatter(l, len, prec, align))
          .toJS,
    ),
  );

  // DateTimeFormatter — 7 statics, each (locale, [len, precision, align, year]).
  put(
    module,
    'DateTimeFormatter',
    staticClass({
      for (final e in const {
        'createDt': 'd',
        'createDet': 'de',
        'createEt': 'e',
        'createMdt': 'md',
        'createMdet': 'mde',
        'createYmdt': 'ymd',
        'createYmdet': 'ymde',
      }.entries)
        e.key:
            ((
                  JSObject l, [
                  JSObject? len,
                  JSObject? prec,
                  JSObject? align,
                  JSObject? year,
                ]) => _dateTimeFormatter(e.value, l, len, prec, align, year))
                .toJS,
    }),
  );

  // Zones.
  put(
    module,
    'TimeZone',
    staticClass({
      'createFromIanaId': ((JSString id) => _timeZone(id.toDart)).toJS,
    }),
  );
  put(
    module,
    'UtcOffset',
    staticClass({
      'fromSeconds':
          ((JSNumber s) => JSObject()..setProperty('seconds'.toJS, s)).toJS,
    }),
  );

  const zoneStyles = [
    'SpecificLong',
    'SpecificShort',
    'GenericLong',
    'GenericShort',
    'LocalizedOffsetLong',
    'LocalizedOffsetShort',
    'Location',
    'ExemplarCity',
  ];
  put(
    module,
    'TimeZoneFormatter',
    staticClass({
      for (final s in zoneStyles)
        'create$s': ((JSObject l) => _timeZoneFormatter(localeTag(l), s)).toJS,
    }),
  );
  put(
    module,
    'ZonedDateTimeFormatter',
    staticClass({
      for (final s in zoneStyles)
        'create$s': ((JSObject l, JSObject fmt) => _zonedDateTimeFormatter(
          localeTag(l),
          s,
          fmt,
        )).toJS,
    }),
  );
}
