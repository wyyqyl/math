import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:math/models/performance_model.dart';
import 'package:math/models/profile_model.dart';
import 'package:math/models/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileManager extends ChangeNotifier {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;

  ProfileManager._internal();

  late SharedPreferences _prefs;
  List<String> _profileNames = [];
  String _currentProfileName = 'Default';

  Profile? _currentProfile;

  List<String> get profileNames => _profileNames;
  Profile? get currentProfile => _currentProfile;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _profileNames = _prefs.getStringList('profile_list') ?? [];

    if (_profileNames.isEmpty) {
      await createProfile('Default', makeActive: true);
    } else {
      _currentProfileName =
          _prefs.getString('active_profile') ?? _profileNames.first;
      await _loadProfile(_currentProfileName);
    }
  }

  Future<void> _loadProfile(String name) async {
    final tables = _prefs.getStringList('profile_${name}_selectedTables');
    final duration = _prefs.getInt('profile_${name}_quizDuration');
    final limit = _prefs.getInt('profile_${name}_additionSubtractionLimit');
    final advanced = _prefs.getBool('profile_${name}_advancedMode');

    _currentProfile = Profile(
      name: name,
      settings: AppSettings(
        selectedTables:
            tables?.map(int.parse).toList() ?? [2, 3, 4, 5, 6, 7, 8, 9],
        quizDuration: duration ?? 60,
        additionSubtractionLimit: limit ?? 10,
        advancedMode: advanced ?? false,
      ),
    );
    _currentProfileName = name;
    await _prefs.setString('active_profile', name);
    notifyListeners();
  }

  Future<void> createProfile(String name, {bool makeActive = false}) async {
    if (_profileNames.contains(name)) {
      throw Exception('Profile with this name already exists.');
    }
    _profileNames.add(name);
    await _prefs.setStringList('profile_list', _profileNames);

    // Save default settings for the new profile
    final defaultSettings = AppSettings(
      selectedTables: [2, 3, 4, 5, 6, 7, 8, 9],
      quizDuration: 60,
      additionSubtractionLimit: 10,
      advancedMode: false,
    );
    await updateProfileSettings(name, defaultSettings);

    if (makeActive) {
      await switchProfile(name);
    }
    notifyListeners();
  }

  Future<void> switchProfile(String name) async {
    if (_profileNames.contains(name)) {
      await _loadProfile(name);
    }
  }

  Future<void> deleteProfile(String name) async {
    if (!_profileNames.contains(name) || _profileNames.length <= 1) {
      return; // Cannot delete the last profile
    }
    _profileNames.remove(name);
    await _prefs.setStringList('profile_list', _profileNames);

    // Clean up profile data
    await _prefs.remove('profile_${name}_selectedTables');
    await _prefs.remove('profile_${name}_quizDuration');
    await _prefs.remove('profile_${name}_additionSubtractionLimit');
    await _prefs.remove('profile_${name}_advancedMode');
    await _prefs.remove('profile_${name}_performanceData');

    if (_currentProfileName == name) {
      await switchProfile(_profileNames.first);
    }
    notifyListeners();
  }

  Future<void> renameProfile(String oldName, String newName) async {
    if (!_profileNames.contains(oldName) || _profileNames.contains(newName)) {
      throw Exception('Invalid profile name or new name already exists.');
    }
    final index = _profileNames.indexOf(oldName);

    // Migrate data
    final tables = _prefs.getStringList('profile_${oldName}_selectedTables');
    final duration = _prefs.getInt('profile_${oldName}_quizDuration');
    final limit = _prefs.getInt('profile_${oldName}_additionSubtractionLimit');
    final advanced = _prefs.getBool('profile_${oldName}_advancedMode');
    final performance = _prefs.getString('profile_${oldName}_performanceData');

    if (tables != null) {
      await _prefs.setStringList('profile_${newName}_selectedTables', tables);
    }
    if (duration != null) {
      await _prefs.setInt('profile_${newName}_quizDuration', duration);
    }
    if (limit != null) {
      await _prefs.setInt('profile_${newName}_additionSubtractionLimit', limit);
    }
    if (advanced != null) {
      await _prefs.setBool('profile_${newName}_advancedMode', advanced);
    }
    if (performance != null) {
      await _prefs.setString('profile_${newName}_performanceData', performance);
    }

    // Remove old profile data
    await _prefs.remove('profile_${oldName}_selectedTables');
    await _prefs.remove('profile_${oldName}_quizDuration');
    await _prefs.remove('profile_${oldName}_additionSubtractionLimit');
    await _prefs.remove('profile_${oldName}_advancedMode');
    await _prefs.remove('profile_${oldName}_performanceData');

    _profileNames[index] = newName;
    await _prefs.setStringList('profile_list', _profileNames);

    if (_currentProfileName == oldName) {
      await switchProfile(newName);
    } else {
      notifyListeners();
    }
  }

  Future<void> updateProfileSettings(String name, AppSettings settings) async {
    await _prefs.setStringList(
      'profile_${name}_selectedTables',
      settings.selectedTables.map((e) => e.toString()).toList(),
    );
    await _prefs.setInt('profile_${name}_quizDuration', settings.quizDuration);
    await _prefs.setInt(
      'profile_${name}_additionSubtractionLimit',
      settings.additionSubtractionLimit,
    );
    await _prefs.setBool('profile_${name}_advancedMode', settings.advancedMode);
    if (_currentProfileName == name) {
      await _loadProfile(name);
    }
  }

  String getPerformanceKey() {
    return 'profile_${_currentProfileName}_performanceData';
  }

  Future<Map<String, QuestionPerformance>> loadPerformanceData() async {
    final performanceKey = getPerformanceKey();
    final jsonString = _prefs.getString(performanceKey);
    if (jsonString == null) {
      return {};
    }
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap.map((key, value) {
      return MapEntry(key, QuestionPerformance.fromJson(value));
    });
  }

  Future<void> savePerformanceData(
    Map<String, QuestionPerformance> performanceData,
  ) async {
    final performanceKey = getPerformanceKey();
    final Map<String, QuestionPerformance> filteredData = Map.from(
      performanceData,
    )..removeWhere((key, value) => value.appearanceCount == 0);
    final jsonMap = filteredData.map((key, value) {
      return MapEntry(key, value.toJson());
    });
    await _prefs.setString(performanceKey, json.encode(jsonMap));
  }
}
