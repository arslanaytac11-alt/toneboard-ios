import '../models/pedal_definition.dart';

class PedalRegistry {
  static final PedalRegistry shared = PedalRegistry._();
  PedalRegistry._();

  final Map<String, PedalDefinition> _defs = {};
  final Set<String> _unlocked = {};

  void init() {
    _registerFree();
    _registerPremium();
  }

  PedalDefinition? definition(String pedalID) => _defs[pedalID];

  List<PedalDefinition> allDefinitions({PedalCategory? category}) {
    var all = _defs.values.toList();
    if (category != null) all = all.where((d) => d.category == category).toList();
    all.sort((a, b) => a.isPremium ? 1 : -1);
    return all;
  }

  bool isUnlocked(String pedalID) {
    final def = _defs[pedalID];
    if (def == null) return false;
    return !def.isPremium || _unlocked.contains(pedalID);
  }

  void unlock(List<String> pedalIDs) => _unlocked.addAll(pedalIDs);
  void unlockAll() => _unlocked.addAll(_defs.keys);

  void _registerFree() {
    _register(PedalDefinition(
      pedalID: 'free_overdrive', displayName: 'Simple Overdrive',
      category: PedalCategory.gain, isPremium: false,
      defaultParameters: {'gain': 10.0, 'tone': 0.5, 'level': 0.8},
      parameterLabels: {'gain': 'Gain', 'tone': 'Tone', 'level': 'Level'},
      education: EducationContent(summary: 'Sinyali yumuşakça kırarak sıcak, hafif bozuk ton üretir.',
        signalPosition: 'Zincirin başında.', notableUsers: ['Stevie Ray Vaughan', 'Gary Clark Jr.']),
    ));
    _register(PedalDefinition(
      pedalID: 'free_fuzz', displayName: 'Fuzz',
      category: PedalCategory.gain, isPremium: false,
      defaultParameters: {'gain': 60.0, 'clip': 0.7, 'level': 0.8},
      parameterLabels: {'gain': 'Fuzz', 'clip': 'Clip', 'level': 'Volume'},
      education: EducationContent(summary: 'Sert kırpma, vintage rock karakteri.',
        signalPosition: 'Zincirin en başında.', notableUsers: ['Jimi Hendrix', 'Jack White']),
    ));
    _register(PedalDefinition(
      pedalID: 'free_delay', displayName: 'Stereo Delay',
      category: PedalCategory.time, isPremium: false,
      defaultParameters: {'time': 0.25, 'feedback': 0.4, 'mix': 0.4},
      parameterLabels: {'time': 'Time (s)', 'feedback': 'Feedback', 'mix': 'Mix'},
      education: EducationContent(summary: 'Tekrar efekti.',
        signalPosition: "Reverb'den önce.", notableUsers: ['The Edge', 'David Gilmour']),
    ));
    _register(PedalDefinition(
      pedalID: 'free_reverb', displayName: 'Hall Reverb',
      category: PedalCategory.time, isPremium: false,
      defaultParameters: {'dwell': 0.5, 'mix': 0.4},
      parameterLabels: {'dwell': 'Size', 'mix': 'Mix'},
      education: EducationContent(summary: 'Geniş mekan hissi.',
        signalPosition: 'Zincirin en sonunda.', notableUsers: ['Andy Summers']),
    ));
    _register(PedalDefinition(
      pedalID: 'free_chorus', displayName: 'Chorus',
      category: PedalCategory.modulation, isPremium: false,
      defaultParameters: {'wetDry': 50.0},
      parameterLabels: {'wetDry': 'Mix'},
      education: EducationContent(summary: 'Dolgun, sulu ses.',
        signalPosition: "Gain'den sonra.", notableUsers: ['Kurt Cobain']),
    ));
    _register(PedalDefinition(
      pedalID: 'free_wah', displayName: 'Wah',
      category: PedalCategory.filter, isPremium: false,
      defaultParameters: {'cutoff': 800.0, 'resonance': 4.0},
      parameterLabels: {'cutoff': 'Pedal', 'resonance': 'Q'},
      education: EducationContent(summary: 'Frekans süpüren filtre.',
        signalPosition: 'Zincirin başında.', notableUsers: ['Jimi Hendrix', 'Slash']),
    ));
    _register(PedalDefinition(
      pedalID: 'free_tuner', displayName: 'Tuner',
      category: PedalCategory.utility, isPremium: false,
      defaultParameters: {}, parameterLabels: {},
      education: EducationContent(summary: 'Kromatik akort cihazı.',
        signalPosition: 'Zincirin en başında.', notableUsers: []),
    ));
    _register(PedalDefinition(
      pedalID: 'free_clean_boost', displayName: 'Clean Boost',
      category: PedalCategory.gain, isPremium: false,
      defaultParameters: {'gainDB': 12.0}, parameterLabels: {'gainDB': 'Gain (dB)'},
      education: EducationContent(summary: 'Tonu değiştirmeden yükseltir.',
        signalPosition: "Overdrive'dan önce.", notableUsers: ['Eric Johnson']),
    ));
  }

  void _registerPremium() {
    _register(PedalDefinition(
      pedalID: 'premium_green_screamer', displayName: 'Green Screamer',
      category: PedalCategory.gain, isPremium: true,
      defaultParameters: {'drive': 0.5, 'tone': 0.5, 'level': 0.5},
      parameterLabels: {'drive': 'Drive', 'tone': 'Tone', 'level': 'Level'},
      education: EducationContent(summary: 'Mid-boost overdrive, blues-rock karakteri.',
        signalPosition: 'Zincirin başında.', notableUsers: ['Stevie Ray Vaughan', 'Gary Moore']),
    ));
    _register(PedalDefinition(
      pedalID: 'premium_stone_crusher', displayName: 'Stone Crusher',
      category: PedalCategory.gain, isPremium: true,
      defaultParameters: {'gain': 0.7, 'tone': 0.5, 'level': 0.5},
      parameterLabels: {'gain': 'Gain', 'tone': 'Tone', 'level': 'Level'},
      education: EducationContent(summary: 'Agresif hard distortion.',
        signalPosition: 'Zincirin başında.', notableUsers: ['Kurt Cobain', 'Billy Corgan']),
    ));
    _register(PedalDefinition(
      pedalID: 'premium_orange_vibe', displayName: 'Orange Vibe',
      category: PedalCategory.modulation, isPremium: true,
      defaultParameters: {'rate': 0.5, 'depth': 0.6},
      parameterLabels: {'rate': 'Rate', 'depth': 'Depth'},
      education: EducationContent(summary: '4 kademeli vintage phaser.',
        signalPosition: "Gain'den sonra.", notableUsers: ['Eddie Van Halen']),
    ));
    _register(PedalDefinition(
      pedalID: 'premium_velvet_fuzz', displayName: 'Velvet Fuzz',
      category: PedalCategory.gain, isPremium: true,
      defaultParameters: {'sustain': 0.7, 'tone': 0.4, 'volume': 0.6},
      parameterLabels: {'sustain': 'Sustain', 'tone': 'Tone', 'volume': 'Volume'},
      education: EducationContent(summary: 'Yumuşak fuzz, yüksek sustain.',
        signalPosition: 'Zincirin başında.', notableUsers: ['David Gilmour']),
    ));
    _register(PedalDefinition(
      pedalID: 'premium_crystal_echo', displayName: 'Crystal Echo',
      category: PedalCategory.time, isPremium: true,
      defaultParameters: {'time': 0.3, 'feedback': 0.4, 'mix': 0.4},
      parameterLabels: {'time': 'Time', 'feedback': 'Repeat', 'mix': 'Mix'},
      education: EducationContent(summary: 'Analog tap-tempo delay.',
        signalPosition: "Modülasyondan sonra.", notableUsers: ['The Edge', 'David Gilmour']),
    ));
    _register(PedalDefinition(
      pedalID: 'premium_spring_pool', displayName: 'Spring Pool',
      category: PedalCategory.time, isPremium: true,
      defaultParameters: {'dwell': 0.5, 'tone': 0.5, 'mix': 0.4},
      parameterLabels: {'dwell': 'Dwell', 'tone': 'Tone', 'mix': 'Mix'},
      education: EducationContent(summary: 'Yay reverb tank simülasyonu.',
        signalPosition: 'Zincirin en sonunda.', notableUsers: ['Dick Dale', 'Jack White']),
    ));
  }

  void _register(PedalDefinition def) => _defs[def.pedalID] = def;
}
