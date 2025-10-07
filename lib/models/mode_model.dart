enum Mode { learn, practice, quiz }

extension OperationExtension on Mode {
  String get name {
    switch (this) {
      case Mode.learn:
        return "Learn";
      case Mode.practice:
        return "Practice";
      case Mode.quiz:
        return "Quiz";
    }
  }
}
