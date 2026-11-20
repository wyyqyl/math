import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:math/managers/question_manager.dart';
import 'package:math/models/operation_model.dart';
import 'package:math/models/question_model.dart';
import 'package:math/models/settings_model.dart';

import 'widgets/game_board.dart';
import 'widgets/game_tap_sound.dart';
import 'widgets/multiplication_array.dart';
import 'widgets/numeric_keypad.dart';
import 'widgets/study_layout.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.operation,
    required this.settings,
    this.table,
    this.reviewKeys,
  });

  final Operation operation;
  final AppSettings settings;
  final int? table;
  final List<String>? reviewKeys;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const _celebrations = {
    'Amazing!': 'amazing.wav',
    'Brilliant!': 'brilliant.wav',
    'Fantastic!': 'fantastic.wav',
    'Excellent!': 'excellent.wav',
    'Awesome!': 'awesome.wav',
    'Incredible!': 'incredible.wav',
    'Superb!': 'superb.wav',
    'Outstanding!': 'outstanding.wav',
    'Perfect!': 'perfect.wav',
    "You're on fire!": 'on_fire.wav',
  };

  late final QuestionManager _manager;
  final _clock = Stopwatch();
  final _missed = <Question, int>{};
  final _retryAfter = <String, int>{};
  final _reviewQueue = Queue<String>();
  AudioPlayer? _player;
  Timer? _advanceTimer;
  Question? _question;
  String _input = '';
  String? _celebration;
  int? _answer;
  int _total = 0;
  int _correct = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _showHint = false;
  bool _finished = false;
  bool _reviewComplete = false;

  bool get _isReview => widget.reviewKeys != null;
  bool get _isMultiplication => widget.operation == Operation.multiplication;
  String get _title {
    if (_isReview) return 'Review missed facts';
    if (widget.table case final table?) return '$table times table practice';
    return 'Practice ${widget.operation.name.toLowerCase()}';
  }

  @override
  void initState() {
    super.initState();
    _manager = QuestionManager(
      operation: widget.operation,
      selectedTables: widget.table == null
          ? widget.settings.selectedTables
          : [widget.table!],
      additionSubtractionLimit: widget.settings.additionSubtractionLimit,
    );
    _reviewQueue.addAll(widget.reviewKeys?.toSet() ?? const <String>{});
    _nextQuestion();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _player?.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    _answer = null;
    _input = '';
    _showHint = false;
    _celebration = null;
    if (_isReview) {
      if (_reviewQueue.isEmpty) {
        _finished = true;
        _reviewComplete = true;
        return;
      }
      _question = _manager.questionForKey(_reviewQueue.removeFirst());
    } else {
      final due = _retryAfter.entries.where((entry) => entry.value <= _total);
      if (due.isNotEmpty) {
        final key = due.first.key;
        _retryAfter.remove(key);
        _question = _manager.questionForKey(key);
      } else {
        _question = _manager.generateQuestion(
          excludeKeys: _retryAfter.keys.toSet(),
        );
      }
    }
    _clock
      ..reset()
      ..start();
  }

  void _submit(int answer, {bool playTap = false}) {
    if (_answer != null || _finished) return;
    if (playTap && widget.settings.soundEnabled) GameTapSound.play();
    _clock.stop();
    final question = _question!;
    final correct = answer == question.correctAnswer;
    setState(() {
      _answer = answer;
      _total++;
      if (correct) _correct++;
      if (correct && !_showHint) {
        _streak++;
        _bestStreak = max(_streak, _bestStreak);
      } else {
        _streak = 0;
      }
      if (!correct) {
        _missed.removeWhere(
          (prior, _) => prior.questionKey == question.questionKey,
        );
        _missed[question] = answer;
      }
      if (!_isReview && (!correct || _showHint)) {
        _retryAfter[question.questionKey] = _total + 2;
      }
      if (_isReview && (!correct || _showHint)) {
        _reviewQueue.addLast(question.questionKey);
      }
      if (_streak > 0 && _streak % 5 == 0) {
        _celebration = _celebrations.keys.elementAt(
          Random().nextInt(_celebrations.length),
        );
      }
    });
    unawaited(
      _manager.recordAnswer(
        question,
        correct,
        _clock.elapsedMilliseconds / 1000,
        usedHint: _showHint,
      ),
    );
    if (widget.settings.soundEnabled && _celebration != null) {
      unawaited(_playCelebration(_celebrations[_celebration]!));
    }
    if (correct) {
      _advanceTimer = Timer(const Duration(seconds: 1), () {
        setState(_nextQuestion);
      });
    }
  }

  Future<void> _playCelebration(String file) async {
    try {
      _player ??= AudioPlayer();
      await _player!.play(AssetSource('audio/$file'));
    } catch (error) {
      debugPrint('Could not play practice sound: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (!_finished)
            TextButton(
              onPressed: () {
                _advanceTimer?.cancel();
                _clock.stop();
                setState(() => _finished = true);
              },
              child: const Text('Finish'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _finished
          ? StudyPage(
              maxWidth: 600,
              centerVertically: true,
              child: _buildSummary(context),
            )
          : _buildPractice(),
    );
  }

  Widget _buildPractice() {
    final question = _question!;
    return GameBoard(
      status: GameStatus(
        items: [
          GameStat(
            icon: Icons.check_circle_outline_rounded,
            label: '$_correct of $_total correct',
          ),
          if (_streak > 1)
            GameStat(icon: Icons.bolt_rounded, label: '$_streak in a row'),
          if (_isReview)
            GameStat(
              icon: Icons.replay_rounded,
              label: '${_reviewQueue.length + (_answer == null ? 1 : 0)} left',
            ),
        ],
      ),
      equation: '${question.expression} = ${_input.isEmpty ? '?' : _input}',
      detail: _showHint
          ? MultiplicationArray(rows: question.num1, columns: question.num2)
          : _isMultiplication && _answer == null
          ? Center(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showHint = true),
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Show a hint'),
              ),
            )
          : null,
      answers: (height) => _answer != null
          ? _buildFeedback(context, question, height)
          : GameAnswers(
              height: height,
              isKeypad: widget.settings.advancedMode,
              controls: (rowHeight) => widget.settings.advancedMode
                  ? NumericKeypad(
                      rowHeight: rowHeight,
                      soundEnabled: widget.settings.soundEnabled,
                      hasInput: _input.isNotEmpty,
                      onNumberPressed: (digit) {
                        if (_input.length < 3) setState(() => _input += digit);
                      },
                      onDeletePressed: () {
                        if (_input.isNotEmpty) {
                          setState(
                            () =>
                                _input = _input.substring(0, _input.length - 1),
                          );
                        }
                      },
                      onSubmitPressed: () {
                        if (int.tryParse(_input) case final answer?) {
                          _submit(answer);
                        }
                      },
                    )
                  : AnswerChoices(
                      question: question,
                      onAnswer: (answer) => _submit(answer, playTap: true),
                      rowHeight: rowHeight,
                    ),
            ),
    );
  }

  Widget _buildFeedback(
    BuildContext context,
    Question question,
    double height,
  ) {
    final correct = _answer == question.correctAnswer;
    final roomy = height > 0;
    final textTheme = Theme.of(context).textTheme;
    return StudyCard(
      minimumHeight: height,
      padding: roomy ? 24 : 16,
      color: correct ? studyMint : studyGold,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Column(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: correct && roomy ? 56 : 24,
                    backgroundColor: correct ? studyGreen : Colors.white,
                    foregroundColor: correct ? Colors.white : studyBlue,
                    child: Icon(
                      correct
                          ? Icons.check_rounded
                          : Icons.lightbulb_outline_rounded,
                      size: correct && roomy ? 76 : 32,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  correct ? 'Correct!' : 'Let’s work it out',
                  style: correct
                      ? textTheme.displayMedium?.copyWith(
                          color: studyGreen,
                          fontSize: roomy ? 64 : 36,
                        )
                      : textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if (_celebration case final message?) Text(message),
                if (!correct) Text('You answered $_answer.'),
                Text(
                  question.equation,
                  style: correct
                      ? textTheme.displaySmall?.copyWith(
                          color: studyGreen,
                          fontSize: roomy ? 58 : 30,
                        )
                      : textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (!correct && _isMultiplication && !_showHint) ...[
            const SizedBox(height: 8),
            MultiplicationArray(rows: question.num1, columns: question.num2),
          ],
          if (!correct) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (_answer == null || _finished) return;
                if (widget.settings.soundEnabled) GameTapSound.play();
                setState(_nextQuestion);
              },
              child: const Text('Next question'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudyCard(
          color: studyTint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _reviewComplete ? 'Review complete!' : 'Practice complete',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text('$_correct of $_total correct · Best streak $_bestStreak'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_missed.isNotEmpty) ...[
          AnswerReview(answers: _missed),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
