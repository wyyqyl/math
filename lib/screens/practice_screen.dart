import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:math/managers/question_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:math/models/operation_model.dart';
import 'package:math/models/question_model.dart';
import 'package:math/models/settings_model.dart';
import 'widgets/numeric_keypad.dart';

class PracticeQuestionRecord {
  final Question question;
  int errorCount;
  double totalTime;
  int attemptCount;

  PracticeQuestionRecord({
    required this.question,
    this.errorCount = 0,
    this.totalTime = 0,
    this.attemptCount = 0,
  });
}

class PracticeScreen extends StatefulWidget {
  final Operation operation;
  final AppSettings settings;

  const PracticeScreen({
    super.key,
    required this.operation,
    required this.settings,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  Question? _currentQuestion;
  int? _selectedOption;
  bool? _isCorrect;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  Timer? _timer;
  double _timeUsed = 0.0;
  int _timeToDisplay = 0;
  QuestionManager? _questionManager;

  // For advanced mode
  String _userInput = '';
  bool _showResult = false;
  bool _isAnswerCorrect = false;
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  // New: Track question history
  final Map<String, PracticeQuestionRecord> _questionHistory = {};

  // New: Streak and engagement features
  int _currentStreak = 0;
  int _bestStreak = 0;
  late AnimationController _starAnimationController;
  late AnimationController _confettiController;
  bool _showConfetti = false;
  final List<String> _encouragementMessages = [
    "Amazing! 🌟",
    "You're on fire! 🔥",
    "Brilliant! ✨",
    "Fantastic! 🎉",
    "Superb! 💫",
    "Excellent! 🌈",
    "Outstanding! 🎨",
    "Incredible! 🚀",
    "Perfect! 💎",
    "Awesome! ⭐",
  ];
  String _currentEncouragement = "";
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, String> _audioFiles = {
    "Amazing! 🌟": "assets/audio/amazing.wav",
    "You're on fire! 🔥": "assets/audio/on_fire.wav",
    "Brilliant! ✨": "assets/audio/brilliant.wav",
    "Fantastic! 🎉": "assets/audio/fantastic.wav",
    "Superb! 💫": "assets/audio/superb.wav",
    "Excellent! 🌈": "assets/audio/excellent.wav",
    "Outstanding! 🎨": "assets/audio/outstanding.wav",
    "Incredible! 🚀": "assets/audio/incredible.wav",
    "Perfect! 💎": "assets/audio/perfect.wav",
    "Awesome! ⭐": "assets/audio/awesome.wav",
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    _questionManager = await QuestionManager.create(
      operation: widget.operation,
      selectedTables: widget.settings.selectedTables,
      additionSubtractionLimit: widget.settings.additionSubtractionLimit,
    );
    _generateQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    _starAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeUsed = 0;
    _timeToDisplay = 0;
    int counter = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _timeUsed += 0.01;
      counter++;
      if (counter == 100) {
        counter = 0;
        setState(() {
          _timeToDisplay = _timeUsed.toInt();
        });
      }
    });
  }

  String _getAppBarTitle() {
    return 'Practice ${widget.operation.name}';
  }

  void _generateQuestion() {
    setState(() {
      _currentQuestion = _questionManager!.generateQuestion();
      _selectedOption = null;
      _isCorrect = null;
      _userInput = '';
      _showResult = false;
      _isAnswerCorrect = false;
      _currentEncouragement = "";
    });
    _startTimer();
  }

  Future<void> _showEncouragementWithAudio() async {
    final message =
        _encouragementMessages[math.Random().nextInt(
          _encouragementMessages.length,
        )];

    setState(() {
      _currentEncouragement = message;
    });

    // Play audio if file exists
    final audioFile = _audioFiles[message];
    if (audioFile != null) {
      try {
        await _audioPlayer.play(
          AssetSource(audioFile.replaceFirst('assets/', '')),
        );
      } catch (e) {
        // Audio file doesn't exist, continue without sound
        debugPrint('Audio file not found: $audioFile');
      }
    }

    // Animate in (500ms)
    await _starAnimationController.forward(from: 0);

    // Stay visible for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));

    // Animate out (500ms)
    await _starAnimationController.reverse();

    // Clear the message
    if (mounted) {
      setState(() {
        _currentEncouragement = "";
      });
    }
  }

  void _updateQuestionHistory(bool wasCorrect) {
    final questionKey = _currentQuestion!.questionKey;

    if (!_questionHistory.containsKey(questionKey)) {
      _questionHistory[questionKey] = PracticeQuestionRecord(
        question: _currentQuestion!,
      );
    }

    final record = _questionHistory[questionKey]!;
    record.attemptCount++;
    record.totalTime += _timeUsed;
    if (!wasCorrect) {
      record.errorCount++;
    }
  }

  void _checkAnswer(int selectedAnswer) async {
    if (_selectedOption != null) return;
    _timer?.cancel();

    final bool wasCorrect = selectedAnswer == _currentQuestion!.correctAnswer;

    setState(() {
      _totalAnswers++;
      _selectedOption = selectedAnswer;
      _isCorrect = wasCorrect;
      if (wasCorrect) {
        _correctAnswers++;
        _currentStreak++;
        if (_currentStreak > _bestStreak) {
          _bestStreak = _currentStreak;
        }
        _animationController.forward().then(
          (_) => _animationController.reverse(),
        );

        // Show encouragement for streaks
        if (_currentStreak % 5 == 0 && _currentStreak > 0) {
          _showEncouragementWithAudio();

          if (_currentStreak >= 10) {
            _showConfetti = true;
            _confettiController.forward(from: 0).then((_) {
              setState(() => _showConfetti = false);
            });
          }
        }
      } else {
        _currentStreak = 0;
      }
    });

    _updateQuestionHistory(wasCorrect);

    await _questionManager!.updateQuestionPerformance(
      questionKey: _currentQuestion!.questionKey,
      isCorrect: wasCorrect,
      timeTaken: _timeUsed,
    );

    if (_isCorrect!) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _generateQuestion();
        }
      });
    }
  }

  void _handleNumberPressed(String number) {
    if (_showResult) return;
    if (_userInput.length < 4) {
      setState(() {
        _userInput += number;
      });
    }
  }

  void _handleDeletePressed() {
    if (_showResult) return;
    if (_userInput.isNotEmpty) {
      setState(() {
        _userInput = _userInput.substring(0, _userInput.length - 1);
      });
    }
  }

  void _handleSubmitPressed() async {
    if (_userInput.isEmpty || _showResult) return;

    _timer?.cancel();
    final Question currentQuestion = _currentQuestion!;
    final int? userAnswer = int.tryParse(_userInput);

    if (userAnswer == null) return;

    final bool wasCorrect = userAnswer == currentQuestion.correctAnswer;

    setState(() {
      _totalAnswers++;
      _showResult = true;
      _isAnswerCorrect = wasCorrect;
      if (wasCorrect) {
        _correctAnswers++;
        _currentStreak++;
        if (_currentStreak > _bestStreak) {
          _bestStreak = _currentStreak;
        }
        _animationController.forward().then(
          (_) => _animationController.reverse(),
        );

        // Show encouragement for streaks
        if (_currentStreak % 5 == 0 && _currentStreak > 0) {
          _showEncouragementWithAudio();

          if (_currentStreak >= 10) {
            _showConfetti = true;
            _confettiController.forward(from: 0).then((_) {
              setState(() => _showConfetti = false);
            });
          }
        }
      } else {
        _currentStreak = 0;
      }
    });

    _updateQuestionHistory(wasCorrect);

    await _questionManager!.updateQuestionPerformance(
      questionKey: currentQuestion.questionKey,
      isCorrect: wasCorrect,
      timeTaken: _timeUsed,
    );

    if (wasCorrect) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _generateQuestion();
        }
      });
    }
  }

  Color _getButtonColor(int option) {
    if (_selectedOption == null) {
      return Colors.white;
    }
    if (option == _currentQuestion!.correctAnswer) {
      return Colors.green.shade300;
    } else if (option == _selectedOption) {
      return Colors.red.shade300;
    } else {
      return Colors.white;
    }
  }

  void _showStopDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Filter questions with errors and sort them
        final questionsWithErrors =
            _questionHistory.values
                .where((record) => record.errorCount > 0)
                .toList()
              ..sort((a, b) {
                // First sort by error count (descending)
                final errorCompare = b.errorCount.compareTo(a.errorCount);
                if (errorCompare != 0) return errorCompare;
                // Then by average time (descending)
                final avgTimeA = a.totalTime / a.attemptCount;
                final avgTimeB = b.totalTime / b.attemptCount;
                return avgTimeB.compareTo(avgTimeA);
              });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.assessment_rounded,
                color: const Color(0xFF667eea),
                size: 48,
              ),
              const SizedBox(width: 12),
              const Text('🎯 Practice Summary'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea).withValues(alpha: 0.2),
                        const Color(0xFF764ba2).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Total',
                            '$_totalAnswers',
                            Icons.quiz_rounded,
                          ),
                          _buildStatItem(
                            'Correct',
                            '$_correctAnswers',
                            Icons.check_circle_rounded,
                          ),
                          _buildStatItem(
                            'Best Streak',
                            '$_bestStreak',
                            Icons.local_fire_department_rounded,
                          ),
                        ],
                      ),
                      if (_totalAnswers > 0) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _correctAnswers / _totalAnswers,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF667eea),
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_correctAnswers / _totalAnswers * 100).toStringAsFixed(1)}% Accuracy',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Questions with errors
                if (questionsWithErrors.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 64,
                            color: Color(0xFFFFD700),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Perfect! No mistakes! 🎉',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  const Text(
                    'Questions to Review:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667eea),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...questionsWithErrors.map((record) {
                    final avgTime = (record.totalTime / record.attemptCount)
                        .toStringAsFixed(1);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${record.errorCount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          '${record.question.num1} ${record.question.operation.symbol} ${record.question.num2} = ?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Avg time: ${avgTime}s',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to Home'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to main menu
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF667eea), size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667eea),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: _currentQuestion == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _buildPracticeView(),
          ),

          // Confetti effect
          if (_showConfetti)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(_confettiController.value),
                    size: Size.infinite,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPracticeView() {
    final isAdvancedMode = widget.settings.advancedMode;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Header with stats and stop button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF667eea),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_correctAnswers / $_totalAnswers',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Streak indicator
                    if (_currentStreak > 0) ...[
                      FadeTransition(
                        opacity: _starAnimationController,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFFF6B6B),
                              size: 24,
                            ),
                            Text(
                              '$_currentStreak',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    const Icon(Icons.timer, color: Color(0xFFf5576c), size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '$_timeToDisplay s',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFf5576c),
                      ),
                    ),
                  ],
                ),
                // Stop button
                ElevatedButton.icon(
                  onPressed: _showStopDialog,
                  icon: const Icon(Icons.stop_rounded, size: 20),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Encouragement message
          if (_currentEncouragement.isNotEmpty)
            FadeTransition(
              opacity: _starAnimationController,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _starAnimationController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    _currentEncouragement,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          if (_currentEncouragement.isNotEmpty) const SizedBox(height: 20),

          // Question display
          if (_isCorrect == true && !isAdvancedMode)
            ScaleTransition(
              scale: _bounceAnimation,
              child: const Text(
                'Correct! 🎉',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.green)],
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isAdvancedMode && _showResult
                    ? (_isAnswerCorrect
                          ? Colors.green.shade100
                          : Colors.red.shade100)
                    : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: isAdvancedMode && _showResult
                    ? Border.all(
                        color: _isAnswerCorrect ? Colors.green : Colors.red,
                        width: 3,
                      )
                    : null,
              ),
              child: Text(
                isAdvancedMode
                    ? '${_currentQuestion!.num1} ${widget.operation.symbol} ${_currentQuestion!.num2} = ${_userInput.isEmpty ? "?" : _userInput}'
                    : '${_currentQuestion!.num1} ${widget.operation.symbol} ${_currentQuestion!.num2} = ?',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isAdvancedMode && _showResult
                      ? (_isAnswerCorrect
                            ? Colors.green.shade900
                            : Colors.red.shade900)
                      : const Color(0xFF667eea),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 30),
          if (isAdvancedMode)
            NumericKeypad(
              onNumberPressed: _handleNumberPressed,
              onDeletePressed: _handleDeletePressed,
              onSubmitPressed: _handleSubmitPressed,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ..._currentQuestion!.options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _checkAnswer(option),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getButtonColor(option),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                          ),
                          child: Text(
                            '$option',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667eea),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_selectedOption != null && !_isCorrect!)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF667eea),
                          minimumSize: const Size(250, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.3),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BubblegumSans',
                          ),
                        ),
                        onPressed: _generateQuestion,
                        child: const Text('Next Question'),
                      ),
                    ),
                ],
              ),
            ),
          if (isAdvancedMode && _showResult && !_isAnswerCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF667eea),
                  minimumSize: const Size(250, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BubblegumSans',
                  ),
                ),
                onPressed: _generateQuestion,
                child: const Text('Next Question'),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Confetti painter for celebration
class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.progress)
    : particles = List.generate(50, (i) => ConfettiParticle(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress);
      final x =
          particle.startX * size.width + particle.velocityX * progress * 200;
      final y = particle.startY * size.height + progress * size.height * 0.8;
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double size;

  ConfettiParticle(int seed)
    : color = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
      ][seed % 6],
      startX = (seed * 0.037) % 1.0,
      startY = 0.1 + (seed * 0.013) % 0.2,
      velocityX = (seed * 0.1) % 2.0 - 1.0,
      size = 4 + (seed % 4).toDouble();
}
