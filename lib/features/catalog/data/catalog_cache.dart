import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CatalogCache {
  static Future<Box<String>>? _opening;

  static Future<Box<String>> _open() async {
    try {
      await Hive.initFlutter();
      return await Hive.openBox<String>('catalog_responses_v1');
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  static Future<Box<String>> get _box => _opening ??= _open();

  static Future<Map<String, dynamic>?> read(String key) async {
    final raw = (await _box).get(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> write(String key, Map<String, dynamic> data) async {
    await (await _box).put(key, jsonEncode(data));
  }
}
