enum PedalCategory { gain, modulation, time, filter, utility, dynamics }

class EducationContent {
  final String summary;
  final String signalPosition;
  final List<String> notableUsers;
  const EducationContent({required this.summary, required this.signalPosition, required this.notableUsers});
}

class PedalDefinition {
  final String pedalID;
  final String displayName;
  final PedalCategory category;
  final bool isPremium;
  final Map<String, double> defaultParameters;
  final Map<String, String> parameterLabels;
  final EducationContent education;

  const PedalDefinition({
    required this.pedalID, required this.displayName,
    required this.category, required this.isPremium,
    required this.defaultParameters, required this.parameterLabels,
    required this.education,
  });
}
