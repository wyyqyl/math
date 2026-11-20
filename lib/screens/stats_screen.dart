import 'package:material_ui/material_ui.dart';
import 'package:math/managers/profile_manager.dart';
import 'package:math/models/operation_model.dart';
import 'package:math/models/performance_model.dart';
import 'package:math/models/question_model.dart';

import 'practice_screen.dart';
import 'widgets/study_layout.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _profiles = ProfileManager();
  Operation _operation = Operation.multiplication;

  @override
  Widget build(BuildContext context) {
    final profile = _profiles.currentProfile!;
    final facts = _profiles
        .loadPerformanceData()
        .entries
        .where((entry) => entry.key.contains(_operation.symbol))
        .toList();
    final review = facts.where((entry) => entry.value.needsReview).toList()
      ..sort((a, b) => b.value.errorRate.compareTo(a.value.errorRate));
    final history = facts.where((entry) => !entry.value.needsReview).toList()
      ..sort((a, b) => b.value.errorRate.compareTo(a.value.errorRate));
    final attempts = facts.fold(
      0,
      (sum, entry) => sum + entry.value.appearanceCount,
    );
    final mistakes = facts.fold(
      0,
      (sum, entry) => sum + entry.value.timesIncorrect,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('My progress')),
      body: StudyPage(
        maxWidth: 680,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              profile.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final operation in Operation.values)
                  Semantics(
                    selected: _operation == operation,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _operation = operation),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _operation == operation
                            ? studyTint
                            : Colors.white,
                      ),
                      child: Text(operation.name),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            StudyCard(
              color: studyTint,
              child: facts.isEmpty
                  ? Text(
                      'Try some ${_operation.name.toLowerCase()} practice or a quiz to see your progress here.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${facts.length} facts tried',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${attempts - mistakes} correct out of $attempts answers',
                        ),
                      ],
                    ),
            ),
            if (review.isNotEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PracticeScreen(
                        operation: _operation,
                        settings: profile.settings,
                        reviewKeys: review.map((entry) => entry.key).toList(),
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.replay_rounded),
                label: Text(
                  'Review ${review.length} missed ${review.length == 1 ? 'fact' : 'facts'}',
                ),
              ),
              const SizedBox(height: 12),
              _factDetails('Ready to review', review),
            ],
            if (history.isNotEmpty) ...[
              const SizedBox(height: 12),
              _factDetails('Answered independently', history),
            ],
          ],
        ),
      ),
    );
  }

  Widget _factDetails(
    String title,
    List<MapEntry<String, QuestionPerformance>> facts,
  ) {
    return StudyCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          '$title (${facts.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        children: [
          for (final MapEntry(:key, :value) in facts.take(10))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Question.fromKey(key).expression),
              subtitle: Text(
                '${value.timesIncorrect} missed of ${value.appearanceCount} · Avg. ${value.averageTime.toStringAsFixed(1)} s',
              ),
            ),
          if (facts.length > 10)
            const Text('Showing the 10 facts with the most difficulty'),
        ],
      ),
    );
  }
}
