class AppSettings {
  final List<int> selectedTables;
  final int quizDuration;
  final int additionSubtractionLimit;
  final bool advancedMode;

  AppSettings({
    required this.selectedTables,
    required this.quizDuration,
    required this.additionSubtractionLimit,
    this.advancedMode = false,
  });
}
