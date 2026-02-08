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
        title: 'Math Genius!',
        theme: ThemeData(
          primarySwatch: Colors.purple,
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

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  final ProfileManager _profileManager = ProfileManager();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _profileManager.addListener(_onProfileChanged);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _profileManager.removeListener(_onProfileChanged);
    _animationController.dispose();
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
        title: const Text(
          'Math Genius! 🌟',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Hello, ${_profileManager.currentProfile?.name ?? ''}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 32,
            ),
            onPressed: _openStats,
            tooltip: 'Statistics',
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 32,
            ),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _profileManager.currentProfile == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    const SizedBox(height: 8),
                    _buildOperationCard(
                      title: Operation.addition.name,
                      icon: Icons.add_circle_rounded,
                      operation: Operation.addition,
                      modes: [Mode.practice, Mode.quiz],
                      color: const Color(0xFF4ECDC4),
                    ),
                    _buildOperationCard(
                      title: Operation.subtraction.name,
                      icon: Icons.remove_circle_rounded,
                      operation: Operation.subtraction,
                      modes: [Mode.practice, Mode.quiz],
                      color: const Color(0xFFFFE66D),
                    ),
                    _buildOperationCard(
                      title: Operation.multiplication.name,
                      icon: Icons.close_rounded,
                      operation: Operation.multiplication,
                      modes: [Mode.learn, Mode.practice, Mode.quiz],
                      color: const Color(0xFFFF6B6B),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOperationCard({
    required String title,
    required IconData icon,
    required Operation operation,
    required List<Mode> modes,
    required Color color,
  }) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: modes.map((mode) {
                  return _buildModeButton(operation, mode, color);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(Operation operation, Mode mode, Color color) {
    IconData modeIcon;
    switch (mode) {
      case Mode.learn:
        modeIcon = Icons.school_rounded;
        break;
      case Mode.practice:
        modeIcon = Icons.fitness_center_rounded;
        break;
      case Mode.quiz:
        modeIcon = Icons.quiz_rounded;
        break;
    }

    return ElevatedButton.icon(
      onPressed: () {
        _navigateToScreen(operation, mode);
      },
      icon: Icon(modeIcon, size: 20),
      label: Text(mode.name),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.4),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'BubblegumSans',
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

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}
