import 'dart:math';
import 'package:math/models/operation_model.dart';

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
