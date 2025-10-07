import 'dart:math';
import 'package:math/models/operation_model.dart';
import 'package:math/models/performance_model.dart';
import 'package:math/managers/profile_manager.dart';
import 'package:math/models/question_model.dart';

class QuestionManager {
  final Operation operation;
  final List<int> selectedTables;
  final int additionSubtractionLimit;
  Map<String, QuestionPerformance> performanceData;
  final List<String> _possibleQuestions;
  String? lastQuestionKey;

  QuestionManager._({
    required this.operation,
    required this.selectedTables,
    required this.additionSubtractionLimit,
    required this.performanceData,
  }) : _possibleQuestions = _generatePossibleQuestions(
         operation,
         selectedTables,
         additionSubtractionLimit,
       );

  static Future<QuestionManager> create({
    required Operation operation,
    required List<int> selectedTables,
    required int additionSubtractionLimit,
  }) async {
    final performanceData = await ProfileManager().loadPerformanceData();
    return QuestionManager._(
      operation: operation,
      selectedTables: selectedTables,
      additionSubtractionLimit: additionSubtractionLimit,
      performanceData: performanceData,
    );
  }

  static String getQuestionKey(String operation, int num1, int num2) {
    return '${operation}_${num1}x$num2';
  }

  static List<String> _generatePossibleQuestions(
    Operation operation,
    List<int> selectedTables,
    int additionSubtractionLimit,
  ) {
    List<String> questions = [];
    String opKey = operation.toString().split('.').last;
    if (operation == Operation.multiplication) {
      for (int table in selectedTables) {
        for (int i = 2; i <= 9; i++) {
          questions.add(getQuestionKey(opKey, table, i));
        }
      }
    } else {
      for (int i = 1; i <= additionSubtractionLimit; i++) {
        for (int j = 1; j <= additionSubtractionLimit; j++) {
          questions.add(getQuestionKey(opKey, i, j));
        }
      }
    }
    return questions;
  }

  void _recalculatePriorityScores() {
    double maxAvgTime = 0;
    for (String qKey in _possibleQuestions) {
      final q = performanceData[qKey] ?? QuestionPerformance();
      if (q.appearanceCount > 0) {
        if (q.averageTime > maxAvgTime) {
          maxAvgTime = q.averageTime;
        }
      }
    }

    for (String qKey in _possibleQuestions) {
      final q = performanceData[qKey] ?? QuestionPerformance();
      if (q.appearanceCount == 0) {
        q.priorityScore = 1.0;
      } else {
        double errorRate = q.errorRate;
        double normalizedTime = maxAvgTime > 0 ? q.averageTime / maxAvgTime : 0;
        q.priorityScore = (0.7 * errorRate) + (0.3 * normalizedTime) + 0.01;
      }
      performanceData[qKey] = q;
    }
  }

  Question generateQuestion() {
    if (_possibleQuestions.isEmpty) {
      throw StateError(
        'No possible questions to generate. Check settings (e.g., selected tables).',
      );
    }

    if (_possibleQuestions.length == 1) {
      return _createQuestionFromKey(_possibleQuestions.first);
    }

    _recalculatePriorityScores();

    double totalWeight = 0;
    Map<String, double> weights = {};
    List<String> filteredQustions = [..._possibleQuestions]
      ..remove(lastQuestionKey);
    for (String qKey in filteredQustions) {
      double weight = performanceData[qKey]?.priorityScore ?? 1.0;
      weights[qKey] = weight;
      totalWeight += weight;
    }

    final random = Random();
    double randomWeight = random.nextDouble() * totalWeight;
    String selectedQuestionKey = filteredQustions.first;
    for (String qKey in filteredQustions) {
      if (randomWeight < weights[qKey]!) {
        selectedQuestionKey = qKey;
        break;
      }
      randomWeight -= weights[qKey]!;
    }

    lastQuestionKey = selectedQuestionKey;

    return _createQuestionFromKey(selectedQuestionKey);
  }

  List<Question> generateUniqueQuestions(
    int count, {
    List<String> excludeKeys = const [],
  }) {
    _recalculatePriorityScores();

    final availableQuestions = _possibleQuestions
        .where((qKey) => !excludeKeys.contains(qKey))
        .toList();

    // Sort available questions by priority score, descending.
    // Questions the user knows least will be at the beginning.
    availableQuestions.sort((a, b) {
      final scoreA = performanceData[a]?.priorityScore ?? 1.0;
      final scoreB = performanceData[b]?.priorityScore ?? 1.0;
      return scoreB.compareTo(scoreA);
    });

    List<String> selectedQuestionKeys = [];

    if (availableQuestions.isEmpty) {
      return [];
    }

    if (count > availableQuestions.length) {
      // If more questions are requested than available, add all available questions.
      selectedQuestionKeys.addAll(availableQuestions);

      // For the remainder, cycle through the sorted list from the beginning.
      final int remaining = count - availableQuestions.length;
      for (int i = 0; i < remaining; i++) {
        selectedQuestionKeys
            .add(availableQuestions[i % availableQuestions.length]);
      }
    } else {
      // Take the top 'count' questions that the user knows least.
      selectedQuestionKeys = availableQuestions.sublist(0, count);
    }

    // Shuffle the final list to ensure random order.
    selectedQuestionKeys.shuffle();

    // Create Question objects from the selected keys.
    return selectedQuestionKeys
        .map((key) => _createQuestionFromKey(key))
        .toList();
  }

  Question _createQuestionFromKey(String questionKey) {
    List<String> parts = questionKey.split('_').last.split('x');
    int num1 = int.parse(parts[0]);
    int num2 = int.parse(parts[1]);

    return Question.fromNumbers(
      num1: num1,
      num2: num2,
      operation: operation,
      questionKey: questionKey,
    );
  }

  Future<void> updateQuestionPerformance({
    required String questionKey,
    required bool isCorrect,
    required int timeTaken,
  }) async {
    QuestionPerformance performance =
        performanceData[questionKey] ?? QuestionPerformance();

    performance.appearanceCount++;
    performance.totalTimeSpent += timeTaken;
    if (!isCorrect) {
      performance.timesIncorrect++;
    }

    performanceData[questionKey] = performance;
    await ProfileManager().savePerformanceData(performanceData);
  }
}
