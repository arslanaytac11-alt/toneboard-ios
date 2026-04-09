import 'dart:convert';

class PedalInstance {
  final String id;
  final String pedalID;
  Map<String, double> parameters;
  bool isBypassed;

  PedalInstance({
    String? id,
    required this.pedalID,
    Map<String, double>? parameters,
    this.isBypassed = false,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        parameters = parameters ?? {};

  Map<String, dynamic> toJson() => {
    'id': id, 'pedalID': pedalID,
    'parameters': parameters, 'isBypassed': isBypassed,
  };

  factory PedalInstance.fromJson(Map<String, dynamic> json) => PedalInstance(
    id: json['id'], pedalID: json['pedalID'],
    parameters: Map<String, double>.from(json['parameters'] ?? {}),
    isBypassed: json['isBypassed'] ?? false,
  );
}
