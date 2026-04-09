import 'dart:convert';
import 'pedal_instance.dart';

class Preset {
  final String id;
  String name;
  List<PedalInstance> chain;
  final DateTime createdAt;

  Preset({String? id, required this.name, required this.chain, DateTime? createdAt})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'chain': chain.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
    id: json['id'], name: json['name'],
    chain: (json['chain'] as List).map((e) => PedalInstance.fromJson(e)).toList(),
    createdAt: DateTime.parse(json['createdAt']),
  );

  String toBase64() => base64Encode(utf8.encode(jsonEncode(toJson())));

  static Preset fromBase64(String encoded) =>
      Preset.fromJson(jsonDecode(utf8.decode(base64Decode(encoded))));
}
