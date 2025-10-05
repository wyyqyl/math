import 'package:flutter/material.dart';
import 'learn_screen.dart';
import 'practice_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';
import 'settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MathApp());
}

class MathApp extends StatelessWidget {
  const MathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'BubblegumSans',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainMenuScreen(),
    );
  }
}

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
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  List<int> _selectedTables = [];
  int _quizDuration = 60;
  int _additionSubtractionLimit = 10;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final tables = prefs.getStringList('selectedTables');
    final duration = prefs.getInt('quizDuration');
    final limit = prefs.getInt('additionSubtractionLimit');

    setState(() {
      _selectedTables =
          tables?.map(int.parse).toList() ?? [2, 3, 4, 5, 6, 7, 8, 9];
      _quizDuration = duration ?? 60;
      _additionSubtractionLimit = limit ?? 10;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selectedTables',
      _selectedTables.map((e) => e.toString()).toList(),
    );
    await prefs.setInt('quizDuration', _quizDuration);
    await prefs.setInt('additionSubtractionLimit', _additionSubtractionLimit);
  }

  void _openSettings() async {
    final newSettings = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialSelectedTables: _selectedTables,
          initialQuizDuration: _quizDuration,
          initialAdditionSubtractionLimit: _additionSubtractionLimit,
        ),
      ),
    );

    if (newSettings != null) {
      setState(() {
        _selectedTables = newSettings.selectedTables;
        _quizDuration = newSettings.quizDuration;
        _additionSubtractionLimit = newSettings.additionSubtractionLimit;
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Genius!'),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 30),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.yellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : ListView(
                padding: const EdgeInsets.all(8.0),
                children: <Widget>[
                  _buildOperationCard(
                    title: 'Addition',
                    icon: Icons.add,
                    operation: Operation.addition,
                    modes: ['Practice', 'Quiz'],
                  ),
                  _buildOperationCard(
                    title: 'Subtraction',
                    icon: Icons.remove,
                    operation: Operation.subtraction,
                    modes: ['Practice', 'Quiz'],
                  ),
                  _buildOperationCard(
                    title: 'Multiplication',
                    icon: Icons.close,
                    operation: Operation.multiplication,
                    modes: ['Learn', 'Practice', 'Quiz'],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOperationCard({
    required String title,
    required IconData icon,
    required Operation operation,
    required List<String> modes,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: Colors.orange.shade800),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: modes.map((mode) {
                return ElevatedButton(
                  onPressed: () {
                    _navigateToScreen(operation, mode);
                  },
                  child: Text(mode),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(Operation operation, String mode) {
    Widget page;
    if (mode == 'Learn') {
      page = LearnScreen(operation: operation, selectedTables: _selectedTables);
    } else if (mode == 'Practice') {
      page = PracticeScreen(
        operation: operation,
        selectedTables: _selectedTables,
        additionSubtractionLimit: _additionSubtractionLimit,
      );
    } else {
      page = QuizScreen(
        operation: operation,
        selectedTables: _selectedTables,
        quizDuration: _quizDuration,
        additionSubtractionLimit: _additionSubtractionLimit,
      );
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}
