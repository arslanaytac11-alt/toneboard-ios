import 'package:flutter/foundation.dart';
import 'pedal_registry.dart';

class FreemiumGate extends ChangeNotifier {
  static const _limit = 3;
  bool _fullBundle = false;
  final Set<String> _unlocked = {};
  final Set<String> _activeDemos = {};

  bool get isFullBundleUnlocked => _fullBundle;

  bool canAddPedal(int currentCount) => _fullBundle || currentCount < _limit;

  bool isPedalAccessible(String pedalID) {
    final def = PedalRegistry.shared.definition(pedalID);
    if (def == null) return false;
    if (!def.isPremium) return true;
    return _fullBundle || _unlocked.contains(pedalID) || _activeDemos.contains(pedalID);
  }

  void unlock(List<String> pedalIDs) {
    _unlocked.addAll(pedalIDs);
    PedalRegistry.shared.unlock(pedalIDs);
    notifyListeners();
  }

  void unlockFullBundle() {
    _fullBundle = true;
    PedalRegistry.shared.unlockAll();
    notifyListeners();
  }

  void startDemo(String pedalID) {
    _activeDemos.add(pedalID);
    notifyListeners();
    Future.delayed(const Duration(seconds: 60), () {
      _activeDemos.remove(pedalID);
      notifyListeners();
    });
  }

  bool isDemoActive(String pedalID) => _activeDemos.contains(pedalID);
}
