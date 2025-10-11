import 'package:flutter/material.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'managers/profile_manager.dart';
import 'screens/quiz_screen.dart';
import 'screens/settings_screen.dart';
import 'models/settings_model.dart';
import 'models/operation_model.dart';
import 'models/mode_model.dart';
import 'screens/stats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProfileManager().initialize();
  runApp(const MathApp());
}

class MathApp extends StatelessWidget {
  const MathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProfileManager(),
      builder: (context, child) => MaterialApp(
        title: 'Math App',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          fontFamily: 'BubblegumSans',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MainMenuScreen(),
      ),
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final ProfileManager _profileManager = ProfileManager();

  @override
  void initState() {
    super.initState();
    _profileManager.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profileManager.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    setState(() {});
  }

  void _openSettings() async {
    await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Genius!'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            'Profile: ${_profileManager.currentProfile?.name ?? ''}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white, size: 30),
            onPressed: _openStats,
          ),
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
        child: _profileManager.currentProfile == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : ListView(
                padding: const EdgeInsets.all(8.0),
                children: <Widget>[
                  _buildOperationCard(
                    title: Operation.addition.name,
                    icon: Icons.add,
                    operation: Operation.addition,
                    modes: [Mode.practice, Mode.quiz],
                  ),
                  _buildOperationCard(
                    title: Operation.subtraction.name,
                    icon: Icons.remove,
                    operation: Operation.subtraction,
                    modes: [Mode.practice, Mode.quiz],
                  ),
                  _buildOperationCard(
                    title: Operation.multiplication.name,
                    icon: Icons.close,
                    operation: Operation.multiplication,
                    modes: [Mode.learn, Mode.practice, Mode.quiz],
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
    required List<Mode> modes,
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
                  child: Text(mode.name),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(Operation operation, Mode mode) {
    Widget page;
    final settings = _profileManager.currentProfile!.settings;

    switch (mode) {
      case Mode.learn:
        page = LearnScreen(operation: operation, settings: settings);
        break;
      case Mode.practice:
        page = PracticeScreen(operation: operation, settings: settings);
        break;
      case Mode.quiz:
        page = QuizScreen(operation: operation, settings: settings);
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}
