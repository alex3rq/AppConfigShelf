import 'package:shelf_core/shelf_core.dart';
import 'package:test/test.dart';

void main() {
  group('StoragePath.parse tokenized', () {
    test('parses known-folder token with backslashes', () {
      final result = StoragePath.parse(r'%APPDATA%\Code\User');
      final path = result.valueOrNull as TokenizedPath;
      expect(path.root, KnownFolder.appData);
      expect(path.segments, ['Code', 'User']);
      expect(path.stored, r'%APPDATA%\Code\User');
    });

    test('parses forward slashes and mixed separators', () {
      final path =
          StoragePath.parse(r'%LOCALAPPDATA%/Programs\App').valueOrNull!;
      expect(path.segments, ['Programs', 'App']);
    });

    test('token alone is valid', () {
      final path = StoragePath.parse('%DOCUMENTS%').valueOrNull!;
      expect(path.stored, '%DOCUMENTS%');
      expect(path.segments, isEmpty);
    });

    test('token is case-insensitive but stored uppercase', () {
      final path = StoragePath.parse(r'%AppData%\X').valueOrNull!;
      expect(path.stored, r'%APPDATA%\X');
    });

    test('rejects unknown token', () {
      final result = StoragePath.parse(r'%WINDIR%\System32');
      expect(result.failureOrNull, isA<InvalidPathFailure>());
    });

    test('rejects .. traversal', () {
      final result = StoragePath.parse(r'%APPDATA%\..\..\Windows');
      expect(result.failureOrNull, isA<InvalidPathFailure>());
    });

    test('rejects . segment', () {
      expect(StoragePath.parse(r'%APPDATA%\.\x').isOk, isFalse);
    });

    test('rejects empty input', () {
      expect(StoragePath.parse('  ').isOk, isFalse);
    });

    test('rejects relative path without token', () {
      expect(StoragePath.parse(r'Code\User').isOk, isFalse);
    });
  });

  group('StoragePath.parse absolute', () {
    test('rejected by default', () {
      final result = StoragePath.parse(r'C:\Tools\config.ini');
      expect(result.failureOrNull, isA<InvalidPathFailure>());
    });

    test('accepted with allowAbsolute', () {
      final result =
          StoragePath.parse(r'C:\Tools\config.ini', allowAbsolute: true);
      final path = result.valueOrNull as AbsolutePath;
      expect(path.root, r'C:\');
      expect(path.segments, ['Tools', 'config.ini']);
      expect(path.stored, r'C:\Tools\config.ini');
    });

    test('rejects traversal even when absolute is allowed', () {
      final result =
          StoragePath.parse(r'C:\Tools\..\Windows', allowAbsolute: true);
      expect(result.isOk, isFalse);
    });

    test('rejects colon inside segments', () {
      final result =
          StoragePath.parse(r'C:\Tools\ads:stream', allowAbsolute: true);
      expect(result.isOk, isFalse);
    });
  });

  group('equality', () {
    test('tokenized paths with same stored form are equal', () {
      final a = StoragePath.parse(r'%APPDATA%\X\Y').valueOrNull;
      final b = StoragePath.parse(r'%appdata%/X/Y').valueOrNull;
      expect(a, b);
    });
  });
}
