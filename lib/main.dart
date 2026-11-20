import 'package:material_ui/material_ui.dart';

import 'managers/profile_manager.dart';
import 'models/operation_model.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/widgets/study_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProfileManager().initialize();
  runApp(const MathApp());
}

class MathApp extends StatelessWidget {
  const MathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: studyBlue,
        primary: studyBlue,
        surface: studyPaper,
        secondaryContainer: studyTint,
        onSecondaryContainer: studyInk,
      ),
      scaffoldBackgroundColor: studyPaper,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: studyPaper,
        foregroundColor: studyInk,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
    return MaterialApp(
      title: 'Math Genius!',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.copyWith(
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontFamily: 'BubblegumSans',
            color: studyInk,
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: 'BubblegumSans',
            color: studyInk,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: 'BubblegumSans',
            color: studyInk,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: 'BubblegumSans',
            color: studyInk,
          ),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = ProfileManager();
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final profile = manager.currentProfile;
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: const Text(
              'Math Genius!',
              style: TextStyle(fontFamily: 'BubblegumSans', fontSize: 26),
            ),
            actions: [
              if (profile != null) ...[
                IconButton(
                  tooltip: 'My progress',
                  icon: const Icon(Icons.bar_chart_rounded, color: studyBlue),
                  onPressed: () => _open(context, const StatsScreen()),
                ),
                IconButton(
                  tooltip: 'Profiles & settings',
                  icon: const Icon(Icons.settings_rounded, color: studyBlue),
                  onPressed: () => _open(context, const SettingsScreen()),
                ),
              ],
            ],
          ),
          body: profile == null
              ? const Center(child: CircularProgressIndicator())
              : StudyPage(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Hello, ${profile.name}!',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _multiplicationCard(context),
                      const SizedBox(height: 16),
                      StudyColumns(
                        first: _operationCard(context, Operation.addition),
                        second: _operationCard(context, Operation.subtraction),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _multiplicationCard(BuildContext context) {
    final settings = ProfileManager().currentProfile!.settings;
    return Material(
      color: studyBlue,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 620;
          final showSmallTile =
              !wide &&
              constraints.maxWidth >= 294 &&
              MediaQuery.textScalerOf(context).scale(35) <= 42;
          final heading = Text(
            'Multiplication',
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(color: Colors.white, fontSize: wide ? 48 : 35),
          );
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSmallTile)
                Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 10),
                    const ExcludeSemantics(
                      child: _MathTile('×', 0.13, studyGold, size: 42),
                    ),
                  ],
                )
              else
                heading,
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    _open(context, LearnScreen(settings: settings)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: studyBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.grid_on_rounded),
                label: const Text('Explore times tables'),
              ),
              const SizedBox(height: 8),
              _operationActions(context, Operation.multiplication),
            ],
          );
          return Padding(
            padding: EdgeInsets.all(wide ? 32 : 20),
            child: wide
                ? Row(
                    children: [
                      Expanded(flex: 6, child: title),
                      const SizedBox(width: 24),
                      const Expanded(flex: 4, child: _MathTiles()),
                    ],
                  )
                : title,
          );
        },
      ),
    );
  }

  Widget _operationCard(BuildContext context, Operation operation) {
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: studyTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: ExcludeSemantics(
                  child: Text(
                    operation.glyph,
                    style: const TextStyle(
                      color: studyBlue,
                      fontFamily: 'BubblegumSans',
                      fontSize: 31,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  operation.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _operationActions(context, operation),
        ],
      ),
    );
  }

  Widget _operationActions(BuildContext context, Operation operation) {
    final settings = ProfileManager().currentProfile!.settings;
    final onBlue = operation == Operation.multiplication;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Practice ${operation.name}',
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: onBlue ? const Color(0xFF253AA7) : studyTint,
                foregroundColor: onBlue ? Colors.white : studyInk,
              ),
              onPressed: () => _open(
                context,
                PracticeScreen(operation: operation, settings: settings),
              ),
              child: Text(
                operation == Operation.multiplication
                    ? 'Mixed practice'
                    : 'Practice',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            label: '${operation.name} quiz',
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: onBlue ? Colors.white : studyBlue,
                side: BorderSide(color: onBlue ? studyTint : studyOutline),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => _open(
                context,
                QuizScreen(operation: operation, settings: settings),
              ),
              child: const Text('Quiz'),
            ),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _MathTiles extends StatelessWidget {
  const _MathTiles();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Center(
        child: SizedBox(
          width: 228,
          height: 158,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 41,
                child: _MathTile('3', -0.17, studyTint),
              ),
              Positioned(
                left: 76,
                top: 13,
                child: _MathTile('×', 0.13, studyGold),
              ),
              Positioned(
                left: 151,
                top: 51,
                child: _MathTile('4', -0.12, Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MathTile extends StatelessWidget {
  const _MathTile(this.symbol, this.angle, this.color, {this.size = 72});

  final String symbol;
  final double angle;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size + 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40242D60),
              blurRadius: 12,
              offset: Offset(0, 7),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          symbol,
          style: TextStyle(
            color: studyBlue,
            fontFamily: 'BubblegumSans',
            fontSize: size * 0.72,
            height: 1,
          ),
        ),
      ),
    );
  }
}
