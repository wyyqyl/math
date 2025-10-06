class QuestionPerformance {
  int timesIncorrect;
  int appearanceCount;
  int totalTimeSpent;
  double priorityScore;

  QuestionPerformance({
    this.timesIncorrect = 0,
    this.appearanceCount = 0,
    this.totalTimeSpent = 0,
    this.priorityScore = 1.0,
  });

  double get errorRate =>
      appearanceCount == 0 ? 0 : timesIncorrect / appearanceCount;
  double get averageTime =>
      appearanceCount == 0 ? 0 : totalTimeSpent / appearanceCount;

  factory QuestionPerformance.fromJson(Map<String, dynamic> json) {
    return QuestionPerformance(
      timesIncorrect: json["timesIncorrect"] ?? 0,
      appearanceCount: json["appearanceCount"] ?? 0,
      totalTimeSpent: json["totalTimeSpent"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "timesIncorrect": timesIncorrect,
      "appearanceCount": appearanceCount,
      "totalTimeSpent": totalTimeSpent,
    };
  }
}
