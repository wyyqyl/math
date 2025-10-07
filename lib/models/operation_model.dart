enum Operation { addition, subtraction, multiplication }

extension OperationExtension on Operation {
  String get symbol {
    switch (this) {
      case Operation.addition:
        return '+';
      case Operation.subtraction:
        return '-';
      case Operation.multiplication:
        return 'x';
    }
  }

  String get name {
    switch (this) {
      case Operation.addition:
        return 'Addition';
      case Operation.subtraction:
        return 'Subtraction';
      case Operation.multiplication:
        return 'Multiplication';
    }
  }
}
