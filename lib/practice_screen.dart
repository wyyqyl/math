import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';
import 'question_manager.dart';

class PracticeScreen extends StatefulWidget {
  final Operation operation;
  final List<int> selectedTables;
  final int additionSubtractionLimit;

  const PracticeScreen({
    super.key,
    required this.selectedTables,
    required this.operation,
    required this.additionSubtractionLimit,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Question? _currentQuestion;
  int? _selectedOption;
  bool? _isCorrect;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  Timer? _timer;
  int _timeUsed = 0;
  QuestionManager? _questionManager;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    _questionManager = await QuestionManager.create(
      operation: widget.operation,
      selectedTables: widget.selectedTables,
      additionSubtractionLimit: widget.additionSubtractionLimit,
    );
    _generateQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeUsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeUsed++;
      });
    });
  }

  String _getAppBarTitle() {
    switch (widget.operation) {
      case Operation.addition:
        return 'Practice Addition';
      case Operation.subtraction:
        return 'Practice Subtraction';
      case Operation.multiplication:
        return 'Practice Multiplication';
    }
  }

  void _generateQuestion() {
    setState(() {
      // The last question key is now managed inside QuestionManager
      _currentQuestion = _questionManager!.generateQuestion();

      _selectedOption = null;
      _isCorrect = null;
    });
    _startTimer();
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
      }
    });

    await _questionManager!.updateQuestionPerformance(
      questionKey: _currentQuestion!.questionKey,
      isCorrect: wasCorrect,
      timeTaken: _timeUsed,
    );

    if (_isCorrect!) {
      Future.delayed(const Duration(seconds: 1), () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.yellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _currentQuestion == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _buildPracticeView(),
      ),
    );
  }

  Widget _buildPracticeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Score: $_correctAnswers / $_totalAnswers',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              Text(
                'Time: $_timeUsed seconds',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isCorrect == true)
            const Text(
              'Correct!',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 8, color: Colors.lightGreenAccent),
                ],
              ),
            )
          else
            Text(
              'What is ${_currentQuestion!.num1} ${widget.operation.symbol} ${_currentQuestion!.num2}?',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 40),
          ..._currentQuestion!.options.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 20.0,
              ),
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
                  ),
                  child: Text(
                    '$option',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (_selectedOption != null && !_isCorrect!)
            Column(
              children: [
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange.shade800,
                    minimumSize: const Size(250, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'BubblegumSans',
                    ),
                  ),
                  onPressed: _generateQuestion,
                  child: const Text('Next Question'),
                ),
              ],
            ),
          const SizedBox(height: 20), // Add some space at the bottom
        ],
      ),
    );
  }
}
