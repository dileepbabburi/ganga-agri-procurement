import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'local_store.dart';

LocalStore createLocalStore() => _BrowserLocalStore();

class _BrowserLocalStore implements LocalStore {
  static const _farmersKey = 'ganga.farmers.v1';
  static const _weighmentsKey = 'ganga.weighments.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<Farmer>> farmers() async {
    final values = (await _prefs).getStringList(_farmersKey) ?? const [];
    return values
        .map((value) => Farmer.fromMap(
              (jsonDecode(value) as Map<String, dynamic>).cast<String, Object?>(),
            ))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<void> saveFarmer(Farmer farmer) async {
    final values = (await farmers()).where((item) => item.id != farmer.id).toList()
      ..add(farmer);
    await (await _prefs).setStringList(
      _farmersKey,
      values.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }

  @override
  Future<List<Weighment>> weighments() async {
    final values = (await _prefs).getStringList(_weighmentsKey) ?? const [];
    return values
        .map((value) => Weighment.fromMap(
              (jsonDecode(value) as Map<String, dynamic>).cast<String, Object?>(),
            ))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveWeighment(Weighment weighment) async {
    final values = (await weighments())
      ..removeWhere((item) => item.id == weighment.id)
      ..insert(0, weighment);
    await (await _prefs).setStringList(
      _weighmentsKey,
      values.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }
}
