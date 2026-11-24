/// An http(s) site a request may be sent to: scheme, host and
/// port only, with no path, query, fragment or credentials. A rule grants
/// or denies by comparing one of these with `==`, so naming a site covers
/// every request to it.
final class Origin {
  const Origin._(this.value);

  /// [raw] as an http(s) site, such as `https://api.example.com`, or null
  /// when it is not one, or carries a path, query, fragment or
  /// credentials.
  static Origin? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return null;
    }
    return Origin._(Uri(scheme: uri.scheme, host: uri.host, port: uri.port));
  }

  final Uri value;

  @override
  bool operator ==(Object other) => other is Origin && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// A path appended to an [Origin]'s address, never able to change which
/// site is reached: `@evil.example` after `https://a.example` would be a
/// login to `evil.example` if a path could carry an authority of its own.
final class WebPath {
  const WebPath._(this.value);

  /// No path at all: the origin's address is sent as it is.
  static const root = WebPath._('');

  /// [raw] as a path on an origin, optionally with a `?` query, or null
  /// unless it is exactly what is sent. The empty string is [root]: appending
  /// nothing can't change which site is reached. Any other path
  /// starts with exactly one `/`,
  /// carries no `..`, `@` or `#`, no `%25` that a second decode would turn
  /// into an escaped `.`, `/`, `\` or `%`, and a URI parser leaves its path
  /// and query byte for byte as they are.
  ///
  /// A parser collapses `%2e%2e`, `.%2E` and `./` segments, so a path
  /// decided as `/a/%2e%2e/b` would be sent as `/b`. `%252e%252e` passes
  /// through a parser unchanged and becomes `..` at a server that decodes
  /// twice; its `2e` is plain text to the parser, so it is refused in
  /// either case. Any other `%25`, such as `50%25.docx`, is an ordinary
  /// `%`. Escapes must be uppercase hex (`%2F`, not
  /// `%2f`) and unreserved characters must not be escaped (`.`, not
  /// `%2E`), since a parser rewrites both: `Uri.encodeComponent` produces
  /// escapes that pass.
  static WebPath? parse(String raw) {
    if (raw.isEmpty) return root;
    if (!raw.startsWith('/') || raw.startsWith('//')) return null;
    if (raw.contains('..') ||
        raw.contains('@') ||
        raw.contains(_decodesTwiceToStructure) ||
        raw.contains('#')) {
      return null;
    }
    final queryAt = raw.indexOf('?');
    final path = queryAt < 0 ? raw : raw.substring(0, queryAt);
    final query = queryAt < 0 ? null : raw.substring(queryAt + 1);
    final parsed = Uri.tryParse('$_anyOrigin$raw');
    if (parsed == null ||
        parsed.path != path ||
        parsed.hasQuery != (query != null) ||
        (query != null && parsed.query != query)) {
      return null;
    }
    return WebPath._(raw);
  }

  // The origin doesn't change how an http(s) path or query parses.
  static const _anyOrigin = 'https://origin.invalid';

  static final _decodesTwiceToStructure = RegExp(
    '%25(2e|2f|5c|25)',
    caseSensitive: false,
  );

  final String value;

  @override
  bool operator ==(Object other) => other is WebPath && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// The start of the paths something may reach on an origin, such as a
/// Teams conversation's `/amer/v3/conversations/19%3Aabc%40thread.v2/`.
///
/// It is compared by canonical segments: each segment is decoded and
/// encoded again with [Uri.encodeComponent], so `19:` and `19%3A` are the
/// same segment, while a request is still sent exactly as written.
/// RFC 3986 doesn't promise `:` and `%3A` name the same resource, so a
/// server that told them apart could have two sibling resources whose
/// names differ only in encoding. Neither can be at another depth, since
/// `%2F` stays inside its segment and only a literal `/` splits segments.
final class PathPrefix {
  const PathPrefix._(this.value, this._segments);

  /// [raw] as a path prefix, or null unless it starts and ends with `/`,
  /// carries no `?`, is a valid [WebPath], and every segment decodes. `/`
  /// alone is the whole site.
  static PathPrefix? parse(String raw) {
    if (!raw.endsWith('/') || raw.contains('?')) return null;
    if (WebPath.parse(raw) == null) return null;
    final segments = raw == '/'
        ? const <String>[]
        : _canonicalSegments(raw.substring(1, raw.length - 1));
    return segments == null ? null : PathPrefix._(raw, segments);
  }

  final String value;
  final List<String> _segments;

  /// Whether [path], without its query, lies under this prefix: its
  /// canonical segments start with this prefix's and go further, so
  /// `/drives/abc/` covers `/drives/abc/` and `/drives/abc/x` but neither
  /// `/drives/abc` nor `/drives/abcdef/`. False when a segment of [path]
  /// doesn't decode.
  bool covers(WebPath path) {
    final queryAt = path.value.indexOf('?');
    final raw = queryAt < 0 ? path.value : path.value.substring(0, queryAt);
    final segments = _canonicalSegments(raw.isEmpty ? '' : raw.substring(1));
    if (segments == null || segments.length <= _segments.length) return false;
    for (var i = 0; i < _segments.length; i++) {
      if (segments[i] != _segments[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is PathPrefix && other._segments.join('/') == _segments.join('/');

  @override
  int get hashCode => _segments.join('/').hashCode;

  @override
  String toString() => value;
}

/// [joined]'s `/`-separated segments, each decoded and encoded again with
/// [Uri.encodeComponent], or null when one isn't UTF-8. [joined] is from a
/// [WebPath], so every escape in it is well formed.
List<String>? _canonicalSegments(String joined) {
  final canonical = <String>[];
  for (final segment in joined.split('/')) {
    try {
      canonical.add(Uri.encodeComponent(Uri.decodeComponent(segment)));
    } on FormatException {
      return null;
    }
  }
  return canonical;
}

/// The start of the web addresses something may reach: an [origin] and a
/// [pathPrefix] on it, such as where a trajectory's replies go or how far
/// a fetch grant reaches.
final class AddressPrefix {
  const AddressPrefix._(this.origin, this.pathPrefix);

  factory AddressPrefix.of(Origin origin, PathPrefix pathPrefix) =>
      AddressPrefix._(origin, pathPrefix);

  final Origin origin;
  final PathPrefix pathPrefix;

  /// Whether a request to [path] on [to] lies under this prefix.
  bool covers(Origin to, WebPath path) =>
      to == origin && pathPrefix.covers(path);

  @override
  bool operator ==(Object other) =>
      other is AddressPrefix &&
      other.origin == origin &&
      other.pathPrefix == pathPrefix;

  @override
  int get hashCode => Object.hash(origin, pathPrefix);

  @override
  String toString() => '$origin$pathPrefix';
}
