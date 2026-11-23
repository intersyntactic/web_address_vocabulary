import 'web_address.dart';

/// [json] as a `Map<String, Object?>`, or a [FormatException] naming
/// [field].
Map<String, Object?> _object(Object? json, String field) => switch (json) {
  final Map<String, Object?> map => map,
  _ => throw FormatException('$field: not an object'),
};

/// [json] as a [String], or a [FormatException] naming [field].
String _string(Object? json, String field) => switch (json) {
  final String s => s,
  _ => throw FormatException('$field: not a string'),
};

// Origin

Object? encodeOrigin(Origin origin) => origin.value.toString();

Origin decodeOrigin(Object? json, [String field = 'origin']) {
  final raw = _string(json, field);
  return Origin.parse(raw) ??
      (throw FormatException('$field: not an origin ($raw)'));
}

// WebPath

Object? encodeWebPath(WebPath path) => path.value;

WebPath decodeWebPath(Object? json, [String field = 'path']) {
  final raw = _string(json, field);
  if (raw.isEmpty) return WebPath.root;
  return WebPath.parse(raw) ??
      (throw FormatException('$field: not a web path ($raw)'));
}

// PathPrefix

Object? encodePathPrefix(PathPrefix prefix) => prefix.value;

PathPrefix decodePathPrefix(Object? json, [String field = 'pathPrefix']) {
  final raw = _string(json, field);
  return PathPrefix.parse(raw) ??
      (throw FormatException('$field: not a path prefix ($raw)'));
}

// AddressPrefix

Object? encodeAddressPrefix(AddressPrefix prefix) => {
  'origin': encodeOrigin(prefix.origin),
  'pathPrefix': encodePathPrefix(prefix.pathPrefix),
};

AddressPrefix decodeAddressPrefix(
  Object? json, [
  String field = 'addressPrefix',
]) {
  final map = _object(json, field);
  return AddressPrefix.of(
    decodeOrigin(map['origin'], '$field.origin'),
    decodePathPrefix(map['pathPrefix'], '$field.pathPrefix'),
  );
}
