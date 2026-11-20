import 'package:material_ui/material_ui.dart';
import 'package:math/models/question_model.dart';

const studyInk = Color(0xFF242D60);
const studyBlue = Color(0xFF344BC4);
const studyPaper = Color(0xFFF3F5FF);
const studyTint = Color(0xFFE3E9FF);
const studyOutline = Color(0xFFD7DFF5);
const studyGold = Color(0xFFFFEAAB);
const studyGreen = Color(0xFF14694C);
const studyMint = Color(0xFFE0F5E9);

class StudyPage extends StatelessWidget {
  const StudyPage({
    super.key,
    required this.child,
    this.maxWidth = 940,
    this.centerVertically = false,
  });

  final Widget child;
  final double maxWidth;
  final bool centerVertically;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Align(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                minHeight: centerVertically && viewport.maxHeight > 36
                    ? viewport.maxHeight - 36
                    : 0,
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class StudyCard extends StatelessWidget {
  const StudyCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.minimumHeight = 0,
    this.padding = 16,
  });

  final Widget child;
  final Color color;
  final double minimumHeight;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: studyOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: minimumHeight),
        alignment: Alignment.center,
        padding: EdgeInsets.all(padding),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class StudyColumns extends StatelessWidget {
  const StudyColumns({super.key, required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 620) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 12), second],
        );
      },
    );
  }
}

class Equation extends StatelessWidget {
  const Equation({super.key, required this.text, this.fontSize});

  final String text;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.displaySmall
          ?.copyWith(fontSize: fontSize),
      textAlign: TextAlign.center,
    );
  }
}

class AnswerChoices extends StatelessWidget {
  const AnswerChoices({
    super.key,
    required this.question,
    required this.onAnswer,
    this.rowHeight = 68,
  });

  final Question question;
  final ValueChanged<int>? onAnswer;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (final option in question.options.skip(row * 2).take(2)) ...[
                if (option != question.options[row * 2])
                  const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onAnswer == null
                        ? null
                        : () => onAnswer!(option),
                    style: FilledButton.styleFrom(
                      minimumSize: Size(0, rowHeight),
                      textStyle: TextStyle(
                        fontSize: rowHeight >= 100 ? 48 : 30,
                        fontFamily: 'BubblegumSans',
                      ),
                    ),
                    child: Text('$option'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class AnswerReview extends StatelessWidget {
  const AnswerReview({super.key, required this.answers});

  final Map<Question, int> answers;

  @override
  Widget build(BuildContext context) {
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Facts to review',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final entry in answers.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                entry.key.equation,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('Your answer was ${entry.value}'),
            ),
        ],
      ),
    );
  }
}
