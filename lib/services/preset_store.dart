import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preset.dart';

class PresetStore extends ChangeNotifier {
  List<Preset> _presets = [];
  List<Preset> get presets => List.unmodifiable(_presets);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('presets') ?? '[]';
    final list = jsonDecode(raw) as List;
    _presets = list.map((e) => Preset.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> save(Preset preset) async {
    final idx = _presets.indexWhere((p) => p.id == preset.id);
    if (idx >= 0) { _presets[idx] = preset; } else { _presets.add(preset); }
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _presets.removeWhere((p) => p.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('presets', jsonEncode(_presets.map((p) => p.toJson()).toList()));
  }
}
