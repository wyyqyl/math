import 'dart:math';

import 'package:math/managers/profile_manager.dart';
import 'package:math/models/operation_model.dart';
import 'package:math/models/performance_model.dart';
import 'package:math/models/question_model.dart';
import 'package:math/models/settings_model.dart';

class QuestionManager {
  QuestionManager({
    required Operation operation,
    required List<int> selectedTables,
    required int additionSubtractionLimit,
  }) : _profileName = ProfileManager().currentProfile!.name,
       _possibleQuestions = _generatePossibleQuestions(
         operation,
         selectedTables,
         additionSubtractionLimit,
       ),
       _performance = ProfileManager().loadPerformanceData();

  final String _profileName;
  final List<String> _possibleQuestions;
  final Map<String, QuestionPerformance> _performance;
  final _random = Random();
  String? _lastQuestionKey;

  static List<String> _generatePossibleQuestions(
    Operation operation,
    List<int> selectedTables,
    int limit,
  ) {
    return [
      if (operation == Operation.multiplication)
        for (final table in selectedTables.toSet())
          for (var factor = 1; factor <= AppSettings.maxTable; factor++)
            '$table${operation.symbol}$factor'
      else
        for (var left = 1; left <= limit; left++)
          for (
            var right = 1;
            right <= (operation == Operation.subtraction ? left : limit);
            right++
          )
            '$left${operation.symbol}$right',
    ];
  }

  double _weight(String key) {
    final performance = _performance[key];
    if (performance == null) return 1;
    if (performance.needsReview) return 2 + performance.errorRate;
    return 0.25 + performance.errorRate;
  }

  Question generateQuestion({Set<String> excludeKeys = const {}}) {
    final available = _possibleQuestions
        .where((key) => key != _lastQuestionKey && !excludeKeys.contains(key))
        .toList();
    if (available.isEmpty) return Question.fromKey(_possibleQuestions.first);
    final weights = available.map(_weight).toList();
    var roll = _random.nextDouble() * weights.fold(0.0, (a, b) => a + b);
    var selected = available.last;
    for (var index = 0; index < available.length; index++) {
      roll -= weights[index];
      if (roll < 0) {
        selected = available[index];
        break;
      }
    }
    return questionForKey(selected);
  }

  Question questionForKey(String key) {
    _lastQuestionKey = key;
    return Question.fromKey(key);
  }

  List<Question> generateUniqueQuestions(int count) {
    final available = [..._possibleQuestions]..shuffle(_random);
    final review = <String>[];
    final unseen = <String>[];
    final familiar = <String>[];
    for (final key in available) {
      final performance = _performance[key];
      if (performance == null) {
        unseen.add(key);
      } else if (performance.needsReview) {
        review.add(key);
      } else {
        familiar.add(key);
      }
    }
    final selected = [...review, ...unseen, ...familiar].take(count).toList()
      ..shuffle(_random);
    return selected.map(Question.fromKey).toList();
  }

  Future<void> recordAnswer(
    Question question,
    bool isCorrect,
    double timeTaken, {
    bool usedHint = false,
  }) {
    _performance
        .putIfAbsent(question.questionKey, QuestionPerformance.new)
        .recordAnswer(isCorrect, timeTaken, usedHint: usedHint);
    return ProfileManager().recordAnswer(
      profileName: _profileName,
      questionKey: question.questionKey,
      isCorrect: isCorrect,
      timeTaken: timeTaken,
      usedHint: usedHint,
    );
  }
}
