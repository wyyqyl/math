class QuestionPerformance {
  int timesIncorrect;
  int appearanceCount;
  double totalTimeSpent;
  double priorityScore;

  QuestionPerformance({
    this.timesIncorrect = 0,
    this.appearanceCount = 0,
    this.totalTimeSpent = 0.0,
    this.priorityScore = 1.0,
  });

  double get errorRate =>
      appearanceCount == 0 ? 0 : timesIncorrect / appearanceCount;
  double get averageTime =>
      appearanceCount == 0 ? 0 : totalTimeSpent / appearanceCount;

  factory QuestionPerformance.fromJson(Map<String, dynamic> json) {
    return QuestionPerformance(
      timesIncorrect: json["w"] ?? 0,
      appearanceCount: json["c"] ?? 0,
      totalTimeSpent: double.parse(json["t"] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "w": timesIncorrect,
      "c": appearanceCount,
      "t": totalTimeSpent.toStringAsFixed(2),
    };
  }
}
