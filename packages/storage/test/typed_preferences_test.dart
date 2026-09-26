import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

class _MemoryStorage implements StorageService {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

void main() {
  test('typed values are isolated by namespace', () async {
    final storage = _MemoryStorage();
    final first = TypedPreferences(storage, namespace: 'app.one');
    final second = TypedPreferences(storage, namespace: 'app.two');

    await first.writeBool('welcome', true);
    await first.writeInt('visits', 3);
    await first.writeJson('filters', ['a', 'b'], (value) => value);

    expect(await first.readBool('welcome'), isTrue);
    expect(await first.readInt('visits'), 3);
    expect(
        await first.readJson(
            'filters', (json) => (json as List).cast<String>()),
        ['a', 'b']);
    expect(await second.readBool('welcome'), isNull);
    expect(storage.values.keys, contains('app.one.welcome'));
  });
}
