import 'dart:convert';

import 'package:is_web_address_vocabulary/is_web_address_vocabulary.dart';
import 'package:test/test.dart';

void main() {
  group('Origin', () {
    test('round-trips', () {
      final origin = Origin.parse('https://api.example.com')!;
      expect(decodeOrigin(encodeOrigin(origin)), origin);
    });

    test('refuses a non-origin string', () {
      expect(() => decodeOrigin('not a url'), throwsFormatException);
    });
  });

  group('WebPath', () {
    test('round-trips an ordinary path', () {
      final path = WebPath.parse('/a/b')!;
      expect(decodeWebPath(encodeWebPath(path)), path);
    });

    test('round-trips root', () {
      expect(decodeWebPath(encodeWebPath(WebPath.root)), WebPath.root);
    });

    test('refuses an unsafe path', () {
      expect(() => decodeWebPath('/../x'), throwsFormatException);
      expect(() => decodeWebPath('/@evil.example'), throwsFormatException);
      expect(() => decodeWebPath('/a/%2e%2e/b'), throwsFormatException);
    });
  });

  group('PathPrefix', () {
    test('round-trips as the bare string, as written', () {
      final prefix = PathPrefix.parse('/a/19:x/')!;
      expect(encodePathPrefix(prefix), '/a/19:x/');
      expect(decodePathPrefix(encodePathPrefix(prefix)).value, '/a/19:x/');
    });

    test('refuses one that is not a path prefix', () {
      expect(() => decodePathPrefix('/a'), throwsFormatException);
      expect(() => decodePathPrefix(3), throwsFormatException);
    });
  });

  group('AddressPrefix', () {
    test('round-trips through JSON', () {
      final prefix = AddressPrefix.of(
        Origin.parse('https://graph.microsoft.com')!,
        PathPrefix.parse('/v1.0/drives/d/')!,
      );
      expect(
        decodeAddressPrefix(
          jsonDecode(jsonEncode(encodeAddressPrefix(prefix))),
        ),
        prefix,
      );
    });

    test('refuses a missing or invalid part, naming it', () {
      expect(
        () => decodeAddressPrefix({'origin': 'https://a.example'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('addressPrefix.pathPrefix'),
          ),
        ),
      );
      expect(
        () =>
            decodeAddressPrefix({'origin': 'not a site', 'pathPrefix': '/a/'}),
        throwsFormatException,
      );
    });
  });
}
