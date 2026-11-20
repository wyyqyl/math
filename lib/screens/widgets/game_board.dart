import 'dart:math';

import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:material_ui/material_ui.dart';

import 'study_layout.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.status,
    required this.equation,
    required this.answers,
    this.detail,
  });

  final Widget status;
  final String equation;
  final Widget? detail;
  final Widget Function(double height) answers;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) {
          final split =
              viewport.maxWidth >= 640 &&
              viewport.maxWidth >= viewport.maxHeight;
          final roomy = viewport.maxWidth >= 640 && viewport.maxHeight >= 490;
          final inset = roomy ? 24.0 : 16.0;
          final gap = roomy ? 16.0 : 12.0;
          final stage = roomy ? max(0.0, viewport.maxHeight - 104 - gap) : 0.0;
          final questionHeight = split ? stage : stage * 0.46;
          final answersHeight = split ? stage : stage * 0.54;
          final questionPanel = Semantics(
            container: true,
            sortKey: const OrdinalSortKey(1),
            child: StudyCard(
              color: studyTint,
              minimumHeight: questionHeight,
              padding: roomy ? 24 : 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Equation(text: equation, fontSize: roomy ? 76 : 44),
                  ),
                  if (detail != null) ...[const SizedBox(height: 12), detail!],
                ],
              ),
            ),
          );
          final answerPanel = Semantics(
            container: true,
            sortKey: const OrdinalSortKey(2),
            child: answers(answersHeight),
          );

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(inset, 12, inset, inset),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      container: true,
                      sortKey: const OrdinalSortKey(0),
                      child: status,
                    ),
                    SizedBox(height: gap),
                    if (split)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: questionPanel),
                          SizedBox(width: gap),
                          Expanded(flex: 6, child: answerPanel),
                        ],
                      )
                    else ...[
                      questionPanel,
                      SizedBox(height: gap),
                      answerPanel,
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GameStatus extends StatelessWidget {
  const GameStatus({super.key, required this.items, this.progress});

  final List<Widget> items;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 10, runSpacing: 8, children: items),
        if (progress case final value?) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: studyTint,
            color: studyBlue,
            semanticsLabel: 'Quiz progress',
          ),
        ],
      ],
    );
  }
}

class GameStat extends StatelessWidget {
  const GameStat({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studyOutline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: studyBlue, size: 19),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: studyInk,
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameAnswers extends StatelessWidget {
  const GameAnswers({
    super.key,
    required this.height,
    required this.isKeypad,
    required this.controls,
  });

  final double height;
  final bool isKeypad;
  final Widget Function(double rowHeight) controls;

  @override
  Widget build(BuildContext context) {
    final padding = height > 0 ? 24.0 : 12.0;
    final rowHeight = isKeypad
        ? ((height - 112) / 4).clamp(54.0, 132.0)
        : ((height - 104) / 2).clamp(68.0, 260.0);

    return StudyCard(
      minimumHeight: height,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isKeypad ? 'Type your answer' : 'Choose an answer',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          controls(rowHeight),
        ],
      ),
    );
  }
}
