import 'package:material_ui/material_ui.dart';
import 'package:math/models/operation_model.dart';
import 'package:math/models/settings_model.dart';

import 'practice_screen.dart';
import 'widgets/multiplication_array.dart';
import 'widgets/study_layout.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late int _table = widget.settings.selectedTables.reduce(
    (a, b) => a < b ? a : b,
  );
  int _factor = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Times tables')),
      body: StudyPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick a table',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (
                        var table = 1;
                        table <= AppSettings.maxTable;
                        table++
                      )
                        Semantics(
                          selected: table == _table,
                          label: '$table times table',
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(52, 52),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              backgroundColor: table == _table
                                  ? studyTint
                                  : Colors.white,
                            ),
                            onPressed: () => setState(() => _table = table),
                            child: Text('$table'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeScreen(
                    operation: Operation.multiplication,
                    settings: widget.settings,
                    table: _table,
                  ),
                ),
              ),
              child: Text('Practice the $_table times table'),
            ),
            const SizedBox(height: 12),
            StudyColumns(
              first: StudyCard(
                color: studyTint,
                child: Column(
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Equation(
                        text: '$_table × $_factor = ${_table * _factor}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    MultiplicationArray(rows: _table, columns: _factor),
                    const SizedBox(height: 8),
                    if (_table > 1)
                      Text(
                        List.filled(_table, '$_factor').join(' + '),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            minimumSize: const Size(52, 52),
                          ),
                          tooltip: 'Previous fact',
                          onPressed: _factor > 1
                              ? () => setState(() => _factor--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            'Fact $_factor of 12',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            minimumSize: const Size(52, 52),
                          ),
                          tooltip: 'Next fact',
                          onPressed: _factor < AppSettings.maxTable
                              ? () => setState(() => _factor++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              second: StudyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Jump to a fact',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (
                          var factor = 1;
                          factor <= AppSettings.maxTable;
                          factor++
                        )
                          Semantics(
                            selected: factor == _factor,
                            child: OutlinedButton(
                              onPressed: () => setState(() => _factor = factor),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              child: Text('× $factor'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
