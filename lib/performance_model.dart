import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

class PerformanceTracker {
  static const String _performanceKey = 'questionPerformance';

  static Future<Map<String, QuestionPerformance>> loadPerformanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_performanceKey);
    if (jsonString == null) {
      return {};
    }
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap.map((key, value) {
      return MapEntry(key, QuestionPerformance.fromJson(value));
    });
  }

  static Future<void> savePerformanceData(
    Map<String, QuestionPerformance> performanceData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, QuestionPerformance> filteredData = Map.from(
      performanceData,
    )..removeWhere((key, value) => value.appearanceCount == 0);
    final jsonMap = filteredData.map((key, value) {
      return MapEntry(key, value.toJson());
    });
    await prefs.setString(_performanceKey, json.encode(jsonMap));
  }
}
