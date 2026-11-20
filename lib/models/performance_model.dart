class QuestionPerformance {
  int timesIncorrect;
  int appearanceCount;
  double totalTimeSpent;
  bool? lastAnswerCorrectWithoutHint;

  bool get needsReview =>
      !(lastAnswerCorrectWithoutHint ?? timesIncorrect == 0);

  QuestionPerformance({
    this.timesIncorrect = 0,
    this.appearanceCount = 0,
    this.totalTimeSpent = 0.0,
    this.lastAnswerCorrectWithoutHint,
  });

  double get errorRate =>
      appearanceCount == 0 ? 0 : timesIncorrect / appearanceCount;
  double get averageTime =>
      appearanceCount == 0 ? 0 : totalTimeSpent / appearanceCount;

  void recordAnswer(
    bool isCorrect,
    double timeTaken, {
    required bool usedHint,
  }) {
    appearanceCount++;
    totalTimeSpent += timeTaken;
    if (!isCorrect) timesIncorrect++;
    lastAnswerCorrectWithoutHint = isCorrect && !usedHint;
  }

  factory QuestionPerformance.fromJson(Map<String, dynamic> json) {
    return QuestionPerformance(
      timesIncorrect: json["w"] ?? 0,
      appearanceCount: json["c"] ?? 0,
      totalTimeSpent: double.tryParse('${json["t"]}') ?? 0.0,
      lastAnswerCorrectWithoutHint: json["last"] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "w": timesIncorrect,
      "c": appearanceCount,
      "t": totalTimeSpent.toStringAsFixed(2),
      if (lastAnswerCorrectWithoutHint != null)
        "last": lastAnswerCorrectWithoutHint,
    };
  }
}
