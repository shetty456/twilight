import 'dart:convert';

import 'storage_service.dart';

/// Typed values stored under an app-owned namespace.
///
/// Keep credentials in a secure token store, not in these preferences.
class TypedPreferences {
  const TypedPreferences(this._storage, {required this.namespace})
      : assert(namespace != '');

  final StorageService _storage;
  final String namespace;

  String _key(String name) => '$namespace.$name';

  Future<String?> readString(String name) => _storage.read(_key(name));
  Future<void> writeString(String name, String value) =>
      _storage.write(_key(name), value);

  Future<bool?> readBool(String name) async {
    return switch (await readString(name)) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  Future<void> writeBool(String name, bool value) =>
      writeString(name, value.toString());

  Future<int?> readInt(String name) async =>
      int.tryParse(await readString(name) ?? '');

  Future<void> writeInt(String name, int value) =>
      writeString(name, value.toString());

  Future<T?> readJson<T>(
    String name,
    T Function(Object? json) decode,
  ) async {
    final stored = await readString(name);
    return stored == null ? null : decode(jsonDecode(stored));
  }

  Future<void> writeJson<T>(
    String name,
    T value,
    Object? Function(T value) encode,
  ) =>
      writeString(name, jsonEncode(encode(value)));

  Future<void> delete(String name) => _storage.delete(_key(name));
}
