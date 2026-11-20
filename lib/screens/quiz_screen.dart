import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:math/managers/question_manager.dart';
import 'package:math/models/operation_model.dart';
import 'package:math/models/question_model.dart';
import 'package:math/models/settings_model.dart';

import 'practice_screen.dart';
import 'widgets/game_board.dart';
import 'widgets/game_tap_sound.dart';
import 'widgets/numeric_keypad.dart';
import 'widgets/study_layout.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.operation,
    required this.settings,
  });

  final Operation operation;
  final AppSettings settings;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

enum _QuizPhase { setup, playing, results }

class _QuizScreenState extends State<QuizScreen> {
  static const _roundSize = 10;
  final _clock = Stopwatch();
  late QuestionManager _manager;
  Timer? _ticker;
  Timer? _advance;
  DateTime? _deadline;
  List<Question> _questions = [];
  final _missed = <Question, int>{};
  _QuizPhase _phase = _QuizPhase.setup;
  String _input = '';
  int _answered = 0;
  int _correct = 0;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    _advance?.cancel();
    super.dispose();
  }

  void _start({required bool timed}) {
    _manager = QuestionManager(
      operation: widget.operation,
      selectedTables: widget.settings.selectedTables,
      additionSubtractionLimit: widget.settings.additionSubtractionLimit,
    );
    setState(() {
      _questions = _manager.generateUniqueQuestions(_roundSize);
      _answered = 0;
      _correct = 0;
      _input = '';
      _missed.clear();
      _phase = _QuizPhase.playing;
      _secondsLeft = widget.settings.quizDuration;
      _deadline = timed
          ? DateTime.now().add(Duration(seconds: _secondsLeft))
          : null;
      _resetQuestionClock();
    });
    _ticker?.cancel();
    if (timed) {
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final milliseconds = _deadline!
            .difference(DateTime.now())
            .inMilliseconds;
        final remaining = (milliseconds / 1000).ceil();
        if (remaining <= 0) {
          setState(_finish);
        } else if (remaining != _secondsLeft) {
          setState(() => _secondsLeft = remaining);
        }
      });
    }
  }

  void _resetQuestionClock() {
    _clock
      ..reset()
      ..start();
  }

  void _finish() {
    _ticker?.cancel();
    _advance?.cancel();
    _clock.stop();
    _phase = _QuizPhase.results;
  }

  void _answer(Question question, int answer, {bool playTap = false}) {
    if (_phase != _QuizPhase.playing ||
        _advance?.isActive == true ||
        !identical(_questions[_answered], question)) {
      return;
    }
    if (_deadline case final deadline?
        when !DateTime.now().isBefore(deadline)) {
      setState(_finish);
      return;
    }
    if (playTap && widget.settings.soundEnabled) GameTapSound.play();
    final correct = answer == question.correctAnswer;
    unawaited(
      _manager.recordAnswer(
        question,
        correct,
        _clock.elapsedMilliseconds / 1000,
      ),
    );
    setState(() {
      if (correct) {
        _correct++;
      } else {
        _missed[question] = answer;
      }
      _answered++;
      _input = '';
      if (_answered == _questions.length) {
        _finish();
      } else {
        _advance = Timer(const Duration(milliseconds: 275), () {
          setState(_resetQuestionClock);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.operation.name} quiz')),
      body: switch (_phase) {
        _QuizPhase.playing => _buildQuiz(),
        _QuizPhase.setup => StudyPage(
          maxWidth: 580,
          centerVertically: true,
          child: _buildSetup(context),
        ),
        _QuizPhase.results => StudyPage(
          maxWidth: 600,
          centerVertically: true,
          child: _buildResults(context),
        ),
      },
    );
  }

  Widget _buildSetup(BuildContext context) {
    return StudyCard(
      color: studyTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ready to try 10 questions?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _start(timed: false),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start without a timer'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _start(timed: true),
            icon: const Icon(Icons.timer_outlined),
            label: Text(
              'Start ${widget.settings.quizDuration}-second challenge',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final question = _questions[_answered];
    final acceptingAnswer = _advance?.isActive != true;
    return GameBoard(
      status: GameStatus(
        progress: _answered / _questions.length,
        items: [
          GameStat(
            icon: Icons.flag_outlined,
            label: 'Question ${_answered + 1} of ${_questions.length}',
          ),
          if (_deadline != null)
            GameStat(
              icon: Icons.timer_outlined,
              label: '$_secondsLeft seconds left',
            ),
        ],
      ),
      equation: '${question.expression} = ${_input.isEmpty ? '?' : _input}',
      answers: (height) => GameAnswers(
        height: height,
        isKeypad: widget.settings.advancedMode,
        controls: (rowHeight) => widget.settings.advancedMode
            ? NumericKeypad(
                rowHeight: rowHeight,
                soundEnabled: widget.settings.soundEnabled,
                enabled: acceptingAnswer,
                hasInput: _input.isNotEmpty,
                onNumberPressed: (digit) {
                  if (_input.length < 3) {
                    setState(() => _input += digit);
                  }
                },
                onDeletePressed: () {
                  if (_input.isNotEmpty) {
                    setState(
                      () => _input = _input.substring(0, _input.length - 1),
                    );
                  }
                },
                onSubmitPressed: () {
                  if (int.tryParse(_input) case final answer?) {
                    _answer(question, answer);
                  }
                },
              )
            : AnswerChoices(
                question: question,
                onAnswer: acceptingAnswer
                    ? (answer) => _answer(question, answer, playTap: true)
                    : null,
                rowHeight: rowHeight,
              ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final unanswered = _questions.length - _answered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudyCard(
          color: studyTint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unanswered > 0 ? 'Time is up!' : 'Quiz complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text('$_correct of ${_questions.length} correct'),
              if (unanswered > 0) Text('$unanswered unanswered'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_missed.isNotEmpty) ...[
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PracticeScreen(
                  operation: widget.operation,
                  settings: widget.settings,
                  reviewKeys: _missed.keys
                      .map((question) => question.questionKey)
                      .toList(),
                ),
              ),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Practice missed facts'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          onPressed: () => setState(() => _phase = _QuizPhase.setup),
          child: const Text('New quiz'),
        ),
        if (_missed.isNotEmpty) ...[
          const SizedBox(height: 12),
          AnswerReview(answers: _missed),
        ],
      ],
    );
  }
}
