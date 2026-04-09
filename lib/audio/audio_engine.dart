import 'package:flutter/services.dart';

class AudioEngine {
  static const _channel = MethodChannel('com.toneboard.app/audio');
  bool _isRunning = false;

  Future<void> start() async {
    if (_isRunning) return;
    await _channel.invokeMethod('start');
    _isRunning = true;
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    await _channel.invokeMethod('stop');
    _isRunning = false;
  }

  Future<void> setChain(List<String> pedalIDs) async {
    await _channel.invokeMethod('setChain', {'chain': pedalIDs});
  }

  Future<void> setParameter(String pedalId, String key, double value) async {
    await _channel.invokeMethod('setParameter', {
      'pedalId': pedalId, 'key': key, 'value': value,
    });
  }

  Future<void> setBypass(String pedalId, bool bypassed) async {
    await _channel.invokeMethod('setBypass', {
      'pedalId': pedalId, 'bypassed': bypassed,
    });
  }

  bool get isRunning => _isRunning;
}
