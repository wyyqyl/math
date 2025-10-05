import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';
import 'performance_model.dart';

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
  int? _num1;
  int? _num2;
  int? _correctAnswer;
  List<int> _options = [];
  int? _selectedOption;
  bool? _isCorrect;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  Timer? _timer;
  int _timeUsed = 0;
  Map<String, QuestionPerformance> _performanceData = {};
  List<String> _possibleQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    _performanceData = await PerformanceTracker.loadPerformanceData();
    _possibleQuestions = _getPossibleQuestions();
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

  void _recalculatePriorityScores() {
    double maxAvgTime = 0;
    for (String qKey in _possibleQuestions) {
      final q = _performanceData[qKey] ?? QuestionPerformance();
      if (q.appearanceCount > 0) {
        if (q.averageTime > maxAvgTime) {
          maxAvgTime = q.averageTime;
        }
      }
    }

    for (String qKey in _possibleQuestions) {
      final q = _performanceData[qKey] ?? QuestionPerformance();
      if (q.appearanceCount == 0) {
        q.priorityScore = 1.0;
      } else {
        double errorRate = q.errorRate;
        double normalizedTime = maxAvgTime > 0 ? q.averageTime / maxAvgTime : 0;
        q.priorityScore = (0.7 * errorRate) + (0.3 * normalizedTime) + 0.01;
      }
      _performanceData[qKey] = q;
    }
  }

  void _generateQuestion() {
    _recalculatePriorityScores();
    final random = Random();

    // Weighted random selection based on priorityScore
    double totalWeight = 0;
    Map<String, double> weights = {};
    for (String qKey in _possibleQuestions) {
      double weight = _performanceData[qKey]?.priorityScore ?? 1.0;
      weights[qKey] = weight;
      totalWeight += weight;
    }

    double randomWeight = random.nextDouble() * totalWeight;
    String selectedQuestionKey = _possibleQuestions.first;
    for (String qKey in _possibleQuestions) {
      if (randomWeight < weights[qKey]!) {
        selectedQuestionKey = qKey;
        break;
      }
      randomWeight -= weights[qKey]!;
    }

    List<String> parts = selectedQuestionKey.split('_').last.split('x');
    _num1 = int.parse(parts[0]);
    _num2 = int.parse(parts[1]);

    if (widget.operation == Operation.subtraction) {
      if (_num1! < _num2!) {
        final temp = _num1;
        _num1 = _num2;
        _num2 = temp;
      }
    }

    switch (widget.operation) {
      case Operation.addition:
        _correctAnswer = _num1! + _num2!;
        break;
      case Operation.subtraction:
        _correctAnswer = _num1! - _num2!;
        break;
      case Operation.multiplication:
        _correctAnswer = _num1! * _num2!;
        break;
    }

    _options = {_correctAnswer!}.toList();
    while (_options.length < 4) {
      int wrongOption = _correctAnswer! + random.nextInt(10) - 5;
      if (wrongOption != _correctAnswer &&
          !_options.contains(wrongOption) &&
          wrongOption >= 0) {
        _options.add(wrongOption);
      }
    }
    _options.shuffle();

    setState(() {
      _selectedOption = null;
      _isCorrect = null;
    });
    _startTimer();
  }

  List<String> _getPossibleQuestions() {
    List<String> questions = [];
    String opKey = widget.operation.toString().split('.').last;
    if (widget.operation == Operation.multiplication) {
      for (int table in widget.selectedTables) {
        for (int i = 2; i <= 9; i++) {
          questions.add(PerformanceTracker.getQuestionKey(opKey, table, i));
        }
      }
    } else {
      for (int i = 1; i <= widget.additionSubtractionLimit; i++) {
        for (int j = 1; j <= widget.additionSubtractionLimit; j++) {
          questions.add(PerformanceTracker.getQuestionKey(opKey, i, j));
        }
      }
    }
    return questions;
  }

  void _checkAnswer(int selectedAnswer) {
    if (_selectedOption != null) return;
    _timer?.cancel();

    String questionKey = PerformanceTracker.getQuestionKey(
      widget.operation.toString().split('.').last,
      _num1!,
      _num2!,
    );
    QuestionPerformance performance =
        _performanceData[questionKey] ?? QuestionPerformance();

    performance.appearanceCount++;
    performance.totalTimeSpent += _timeUsed;

    setState(() {
      _totalAnswers++;
      _selectedOption = selectedAnswer;
      _isCorrect = selectedAnswer == _correctAnswer;
      if (_isCorrect!) {
        _correctAnswers++;
      } else {
        performance.timesIncorrect++;
      }
    });

    _performanceData[questionKey] = performance;
    PerformanceTracker.savePerformanceData(_performanceData);

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
    if (option == _correctAnswer) {
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
        child: Center(
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
                  'What is $_num1 ${widget.operation.symbol} $_num2?',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 40),
              ..._options.map((option) {
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
        ),
      ),
    );
  }
}
