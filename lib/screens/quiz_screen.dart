import 'dart:async';
import 'package:flutter/material.dart';
import 'package:math/managers/question_manager.dart';
import 'package:math/models/operation_model.dart';
import 'package:math/models/question_model.dart';
import 'package:math/models/settings_model.dart';
import 'widgets/numeric_keypad.dart';

class QuizScreen extends StatefulWidget {
  final Operation operation;
  final AppSettings settings;

  const QuizScreen({
    super.key,
    required this.operation,
    required this.settings,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalQuestions = 10;

  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  Timer? _timer;
  int _timeLeft = 0;
  List<Question> _incorrectlyAnsweredQuestions = [];
  QuestionManager? _questionManager;
  bool _quizInProgress = true;

  // For advanced mode
  String _userInput = '';
  bool _showResult = false;
  bool _isAnswerCorrect = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeAndStartQuiz();
  }

  Future<void> _initializeAndStartQuiz() async {
    _questionManager = await QuestionManager.create(
      operation: widget.operation,
      selectedTables: widget.settings.selectedTables,
      additionSubtractionLimit: widget.settings.additionSubtractionLimit,
    );
    _startQuiz();
  }

  String _getAppBarTitle() {
    return '${widget.operation.name} Quiz';
  }

  void _generateQuestions() {
    _questions = _questionManager!.generateUniqueQuestions(_totalQuestions);
  }

  void _startQuiz() {
    if (_questionManager == null) return;
    _generateQuestions();
    _currentQuestionIndex = 0;
    _score = 0;
    _timeLeft = widget.settings.quizDuration;
    _quizInProgress = true;
    _incorrectlyAnsweredQuestions = [];
    _userInput = '';
    _showResult = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _endQuiz();
      }
    });
    setState(() {});
  }

  void _endQuiz() {
    _timer?.cancel();
    setState(() {
      _quizInProgress = false;
    });
  }

  void _answerQuestion(int selectedAnswer) {
    final Question currentQuestion = _questions[_currentQuestionIndex];
    final bool isCorrect = currentQuestion.correctAnswer == selectedAnswer;

    if (isCorrect) {
      _score++;
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    }

    if (!isCorrect) {
      _incorrectlyAnsweredQuestions.add(currentQuestion);
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      Future.delayed(Duration(milliseconds: isCorrect ? 500 : 1000), () {
        if (mounted) {
          setState(() {
            _currentQuestionIndex++;
            _userInput = '';
            _showResult = false;
          });
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _endQuiz();
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

  void _handleSubmitPressed() {
    if (_userInput.isEmpty || _showResult) return;

    final Question currentQuestion = _questions[_currentQuestionIndex];
    final int? userAnswer = int.tryParse(_userInput);

    if (userAnswer == null) return;

    final bool isCorrect = userAnswer == currentQuestion.correctAnswer;

    setState(() {
      _showResult = true;
      _isAnswerCorrect = isCorrect;
    });

    if (isCorrect) {
      _score++;
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    } else {
      _incorrectlyAnsweredQuestions.add(currentQuestion);
    }

    Future.delayed(Duration(milliseconds: isCorrect ? 800 : 1500), () {
      if (mounted) {
        if (_currentQuestionIndex < _questions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _userInput = '';
            _showResult = false;
            _isAnswerCorrect = false;
          });
        } else {
          _endQuiz();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE66D), Color(0xFF4ECDC4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _quizInProgress ? _buildQuizView() : _buildResultView(),
      ),
    );
  }

  Widget _buildResultView() {
    final percentage = (_score / _totalQuestions * 100).round();
    String message;
    Color messageColor;

    if (percentage >= 90) {
      message = 'Amazing! You\'re a math genius!';
      messageColor = Colors.green;
    } else if (percentage >= 70) {
      message = 'Great job! Keep practicing!';
      messageColor = Colors.blue;
    } else if (percentage >= 50) {
      message = 'Good effort! You can do better!';
      messageColor = Colors.orange;
    } else {
      message = 'Keep practicing! You\'ll improve!';
      messageColor = Colors.red;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Your Score',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_score / $_totalQuestions',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: messageColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: messageColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: messageColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFFF6B6B),
                minimumSize: const Size(200, 60),
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
              onPressed: _startQuiz,
              child: const Text('Play Again'),
            ),
            if (_incorrectlyAnsweredQuestions.isNotEmpty)
              _buildIncorrectAnswers(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncorrectAnswers() {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            const Text(
              'Review your mistakes:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 16),
            ..._incorrectlyAnsweredQuestions.map(
              (q) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    '${q.num1} ${q.operation.symbol} ${q.num2} = ${q.correctAnswer}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    if (_questions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final isAdvancedMode = widget.settings.advancedMode;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
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
                    const Icon(Icons.timer, color: Color(0xFFFF6B6B), size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '$_timeLeft s',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${_currentQuestionIndex + 1}/$_totalQuestions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
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
                    ? '${currentQuestion.num1} ${currentQuestion.operation.symbol} ${currentQuestion.num2} = ${_userInput.isEmpty ? "?" : _userInput}'
                    : '${currentQuestion.num1} ${currentQuestion.operation.symbol} ${currentQuestion.num2} = ?',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isAdvancedMode && _showResult
                      ? (_isAnswerCorrect
                            ? Colors.green.shade900
                            : Colors.red.shade900)
                      : const Color(0xFFFF6B6B),
                ),
                textAlign: TextAlign.center,
              ),
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
                children: currentQuestion.options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                        ),
                        onPressed: () => _answerQuestion(option),
                        child: Text(
                          '$option',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
