class AppSettings {
  static const maxTable = 12;
  static const defaultTables = [2, 3, 4, 5, 6, 7, 8, 9];

  final List<int> selectedTables;
  final int quizDuration;
  final int additionSubtractionLimit;
  final bool advancedMode;
  final bool soundEnabled;

  const AppSettings({
    required this.selectedTables,
    required this.quizDuration,
    required this.additionSubtractionLimit,
    this.advancedMode = false,
    this.soundEnabled = true,
  });
}
