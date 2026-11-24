import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:is_web_address_vocabulary/is_web_address_vocabulary.dart';
import 'package:test/test.dart';

/// Each public named constant, keyed `Type.name`, with whether reading its
/// value back through the type's own `parse` gives the same value.
final Map<String, bool Function()> _roundTrips = {
  'WebPath.root': () => WebPath.parse(WebPath.root.value) == WebPath.root,
};

/// `Type.name` for every public `static const` declared in `lib/`, read
/// from the parse tree so a comment or string can't add or hide one.
Set<String> _declaredNamedConstants() => {
  for (final file in Directory('lib').listSync(recursive: true))
    if (file is File && file.path.endsWith('.dart'))
      for (final declaration in parseString(
        content: file.readAsStringSync(),
        throwIfDiagnostics: false,
      ).unit.declarations.whereType<ClassDeclaration>())
        for (final member
            in declaration.body.members.whereType<FieldDeclaration>())
          if (member.isStatic && member.fields.isConst)
            for (final variable in member.fields.variables)
              if (!variable.name.lexeme.startsWith('_'))
                '${declaration.namePart.typeName.lexeme}'
                    '.${variable.name.lexeme}',
};

void main() {
  test('every public named constant has a round trip below', () {
    expect(_roundTrips.keys.toSet(), _declaredNamedConstants());
  });

  for (final MapEntry(key: name, value: roundTrips) in _roundTrips.entries) {
    test('$name reads back through parse as itself', () {
      expect(roundTrips(), isTrue);
    });
  }
}
