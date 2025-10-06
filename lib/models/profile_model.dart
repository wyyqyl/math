import 'package:math/models/settings_model.dart';

class Profile {
  String name;
  AppSettings settings;

  Profile({required this.name, required this.settings});

  factory Profile.defaultProfile() {
    return Profile(
        name: 'Default',
        settings: AppSettings(selectedTables: [2,3,4,5,6,7,8,9], quizDuration: 60, additionSubtractionLimit: 10));
  }
}