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

  String get expression => '$num1 ${operation.glyph} $num2';
  String get equation => '$expression = $correctAnswer';

  factory Question.fromKey(String key) {
    final operation = Operation.values.firstWhere(
      (op) => key.contains(op.symbol),
    );
    final parts = key.split(operation.symbol);
    final n1 = int.parse(parts[0]);
    final n2 = int.parse(parts[1]);
    final answer = switch (operation) {
      Operation.addition => n1 + n2,
      Operation.subtraction => n1 - n2,
      Operation.multiplication => n1 * n2,
    };

    final nearby = [
      if (operation == Operation.multiplication) ...[
        n1 * (n2 - 1),
        n1 * (n2 + 1),
        (n1 - 1) * n2,
        (n1 + 1) * n2,
      ] else
        for (var offset = 1; offset <= 5; offset++) ...[
          answer - offset,
          answer + offset,
        ],
    ].where((option) => option >= 0 && option != answer).toList()..shuffle();

    final options = {answer};
    options.addAll(nearby.toSet().take(3));
    for (var offset = 1; options.length < 4; offset++) {
      options.add(answer + offset);
    }

    return Question(
      num1: n1,
      num2: n2,
      correctAnswer: answer,
      options: options.toList()..shuffle(),
      operation: operation,
      questionKey: key,
    );
  }
}
