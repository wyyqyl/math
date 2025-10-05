import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class QuizQuestion {
  final int num1;
  final int num2;
  final int correctAnswer;
  final List<int> options;
  final Operation operation;

  QuizQuestion({
    required this.num1,
    required this.num2,
    required this.correctAnswer,
    required this.options,
    required this.operation,
  });
}

class QuizScreen extends StatefulWidget {
  final Operation operation;
  final List<int> selectedTables;
  final int quizDuration;
  final int additionSubtractionLimit;

  const QuizScreen({
    super.key,
    required this.selectedTables,
    required this.quizDuration,
    required this.operation,
    required this.additionSubtractionLimit,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int _totalQuestions = 10;

  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  Timer? _timer;
  int _timeLeft = 0;
  List<QuizQuestion> _incorrectlyAnsweredQuestions = [];
  bool _quizInProgress = true; // Start quiz immediately

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  String _getAppBarTitle() {
    switch (widget.operation) {
      case Operation.addition:
        return 'Addition Quiz';
      case Operation.subtraction:
        return 'Subtraction Quiz';
      case Operation.multiplication:
        return 'Multiplication Quiz';
    }
  }

  void _generateQuestions() {
    final random = Random();
    final generatedQuestions = <QuizQuestion>[];
    for (int i = 0; i < _totalQuestions; i++) {
      int num1, num2;
      if (widget.operation == Operation.multiplication) {
        num1 =
            widget.selectedTables[random.nextInt(widget.selectedTables.length)];
        num2 = random.nextInt(8) + 2;
      } else {
        num1 = random.nextInt(widget.additionSubtractionLimit) + 1;
        num2 = random.nextInt(widget.additionSubtractionLimit) + 1;
      }

      if (widget.operation == Operation.subtraction) {
        if (num1 < num2) {
          final temp = num1;
          num1 = num2;
          num2 = temp;
        }
      }

      int correctAnswer;
      switch (widget.operation) {
        case Operation.addition:
          correctAnswer = num1 + num2;
          break;
        case Operation.subtraction:
          correctAnswer = num1 - num2;
          break;
        case Operation.multiplication:
          correctAnswer = num1 * num2;
          break;
      }

      final options = {correctAnswer}.toList();
      while (options.length < 4) {
        int wrongOption = correctAnswer + random.nextInt(19) - 9;
        if (wrongOption != correctAnswer &&
            !options.contains(wrongOption) &&
            wrongOption >= 0) {
          options.add(wrongOption);
        }
      }
      options.shuffle();
      generatedQuestions.add(
        QuizQuestion(
          num1: num1,
          num2: num2,
          correctAnswer: correctAnswer,
          options: options,
          operation: widget.operation,
        ),
      );
    }
    _questions = generatedQuestions;
  }

  void _startQuiz() {
    _generateQuestions();
    _currentQuestionIndex = 0;
    _score = 0;
    _timeLeft = widget.quizDuration;
    _quizInProgress = true;
    _incorrectlyAnsweredQuestions = [];

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
    final currentQuestion = _questions[_currentQuestionIndex];
    if (currentQuestion.correctAnswer == selectedAnswer) {
      _score++;
    } else {
      _incorrectlyAnsweredQuestions.add(currentQuestion);
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _endQuiz();
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
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.yellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _quizInProgress ? _buildQuizView() : _buildResultView(),
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your Score',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '$_score / $_totalQuestions',
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                backgroundColor: Colors.white,
                minimumSize: const Size(200, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                textStyle: const TextStyle(
                  fontSize: 24,
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
      child: Column(
        children: [
          const Text(
            'Review your mistakes:',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ..._incorrectlyAnsweredQuestions.map(
            (q) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                title: Text(
                  '${q.num1} ${q.operation.symbol} ${q.num2} = ${q.correctAnswer}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    final currentQuestion = _questions[_currentQuestionIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Time Left: $_timeLeft',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            Text(
              'Question ${_currentQuestionIndex + 1}/${_questions.length}',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'What is ${currentQuestion.num1} ${currentQuestion.operation.symbol} ${currentQuestion.num2}?',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ...currentQuestion.options.map((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 20.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _answerQuestion(option),
                child: Text(
                  '$option',
                  style: TextStyle(fontSize: 28, color: Colors.orange.shade900),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
