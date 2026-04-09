import 'package:flutter_test/flutter_test.dart';
import 'package:toneboard/models/pedal_instance.dart';
import 'package:toneboard/models/preset.dart';
import 'package:toneboard/services/pedal_registry.dart';
import 'package:toneboard/services/freemium_gate.dart';

void main() {
  group('PedalInstance', () {
    test('encodes and decodes correctly', () {
      final instance = PedalInstance(pedalID: 'free_overdrive', parameters: {'gain': 10.0});
      final json = instance.toJson();
      final decoded = PedalInstance.fromJson(json);
      expect(decoded.pedalID, 'free_overdrive');
      expect(decoded.parameters['gain'], 10.0);
    });
  });

  group('Preset', () {
    test('roundtrip base64 encoding', () {
      final preset = Preset(name: 'Test', chain: [
        PedalInstance(pedalID: 'free_delay', parameters: {'time': 0.3}),
      ]);
      final encoded = preset.toBase64();
      final decoded = Preset.fromBase64(encoded);
      expect(decoded.name, 'Test');
      expect(decoded.chain.length, 1);
      expect(decoded.chain[0].pedalID, 'free_delay');
    });
  });

  group('PedalRegistry', () {
    setUp(() => PedalRegistry.shared.init());

    test('contains all 8 free pedals', () {
      final freeIDs = ['free_overdrive', 'free_fuzz', 'free_delay', 'free_reverb',
                       'free_chorus', 'free_wah', 'free_tuner', 'free_clean_boost'];
      for (final id in freeIDs) {
        expect(PedalRegistry.shared.definition(id), isNotNull, reason: 'Missing: $id');
      }
    });

    test('premium pedal not unlocked by default', () {
      expect(PedalRegistry.shared.isUnlocked('premium_green_screamer'), isFalse);
    });
  });

  group('FreemiumGate', () {
    test('free user limited to 3 pedals', () {
      final gate = FreemiumGate();
      expect(gate.canAddPedal(2), isTrue);
      expect(gate.canAddPedal(3), isFalse);
    });

    test('full bundle removes limit', () {
      final gate = FreemiumGate();
      gate.unlockFullBundle();
      expect(gate.canAddPedal(20), isTrue);
    });
  });
}
