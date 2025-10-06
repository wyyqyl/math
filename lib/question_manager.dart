import 'dart:math';
import 'package:math/main.dart';
import 'package:math/performance_model.dart';
import 'package:math/profile_manager.dart';

class Question {
  final int num1;
  final int num2;
  final int correctAnswer;
  final List<int> options;
  final Operation operation;
  final String questionKey;

  Question({
    required this.num1,
    required this.num2,
    required this.correctAnswer,
    required this.options,
    required this.operation,
    required this.questionKey,
  });

  factory Question.fromNumbers({
    required int num1,
    required int num2,
    required Operation operation,
    required String questionKey,
  }) {
    int n1 = num1;
    int n2 = num2;
    if (operation == Operation.subtraction) {
      if (n1 < n2) {
        final temp = n1;
        n1 = n2;
        n2 = temp;
      }
    }

    int correctAnswer;
    switch (operation) {
      case Operation.addition:
        correctAnswer = n1 + n2;
        break;
      case Operation.subtraction:
        correctAnswer = n1 - n2;
        break;
      case Operation.multiplication:
        correctAnswer = n1 * n2;
        break;
    }

    final options = {correctAnswer}.toList();
    final random = Random();
    while (options.length < 4) {
      int wrongOption = correctAnswer + random.nextInt(19) - 9;
      if (wrongOption != correctAnswer &&
          !options.contains(wrongOption) &&
          wrongOption >= 0) {
        options.add(wrongOption);
      }
    }
    options.shuffle();
    return Question(
      num1: n1,
      num2: n2,
      correctAnswer: correctAnswer,
      options: options,
      operation: operation,
      questionKey: questionKey,
    );
  }
}

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

    if (count > availableQuestions.length) {
      // Not enough unique questions available.
      // Add all unique questions, then add the highest-weighted ones to fill the gap.
      final List<Question> generatedQuestions = [];

      // 1. Add all unique questions.
      for (final qKey in availableQuestions) {
        generatedQuestions.add(_createQuestionFromKey(qKey));
      }

      // 2. Find the highest-weighted questions to add as duplicates.
      final int remainingCount = count - availableQuestions.length;
      if (remainingCount > 0 && availableQuestions.isNotEmpty) {
        final sortedByWeight = List<String>.from(availableQuestions);
        sortedByWeight.sort(
          (a, b) => (performanceData[b]?.priorityScore ?? 1.0).compareTo(
            performanceData[a]?.priorityScore ?? 1.0,
          ),
        );

        for (int i = 0; i < remainingCount; i++) {
          // Cycle through the sorted list if more duplicates are needed than available questions
          final qKey = sortedByWeight[i % sortedByWeight.length];
          generatedQuestions.add(_createQuestionFromKey(qKey));
        }
      }

      // 3. Randomly sort the final list.
      generatedQuestions.shuffle();
      return generatedQuestions;
    }

    double totalWeight = 0;
    Map<String, double> weights = {};
    for (String qKey in availableQuestions) {
      double weight = performanceData[qKey]?.priorityScore ?? 1.0;
      weights[qKey] = weight;
      totalWeight += weight;
    }

    final random = Random();
    final List<Question> generatedQuestions = [];
    final Set<String> selectedKeys = {};

    while (generatedQuestions.length < count) {
      double randomWeight = random.nextDouble() * totalWeight;
      String? selectedQuestionKey;

      for (String qKey in availableQuestions) {
        if (selectedKeys.contains(qKey)) continue;

        if (randomWeight < weights[qKey]!) {
          selectedQuestionKey = qKey;
          break;
        }
        randomWeight -= weights[qKey]!;
      }

      // Fallback in case of floating point inaccuracies
      selectedQuestionKey ??= availableQuestions.lastWhere(
        (q) => !selectedKeys.contains(q),
      );

      selectedKeys.add(selectedQuestionKey);
      totalWeight -= weights[selectedQuestionKey]!;

      generatedQuestions.add(_createQuestionFromKey(selectedQuestionKey));
    }
    return generatedQuestions;
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
