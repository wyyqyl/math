import 'package:flutter/material.dart';
import 'package:math/main.dart';
import 'package:math/models/settings_model.dart';

class LearnScreen extends StatelessWidget {
  final Operation operation;
  final AppSettings settings;

  const LearnScreen({
    super.key,
    required this.operation,
    required this.settings,
  });

  String _getAppBarTitle() {
    switch (operation) {
      case Operation.addition:
        return 'Learn Addition';
      case Operation.subtraction:
        return 'Learn Subtraction';
      case Operation.multiplication:
        return 'Learn Multiplication';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a sorted copy of the list to ensure tables are displayed in order.
    final sortedTables = List<int>.from(settings.selectedTables)..sort();

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
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedTables.length,
          itemBuilder: (context, index) {
            final tableNumber = sortedTables[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  'Table of $tableNumber',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                children: List.generate(9, (i) {
                  final multiplier = i + 1;
                  int result;
                  switch (operation) {
                    case Operation.addition:
                      result = tableNumber + multiplier;
                      break;
                    case Operation.subtraction:
                      result = tableNumber - multiplier;
                      break;
                    case Operation.multiplication:
                      result = tableNumber * multiplier;
                      break;
                  }
                  return ListTile(
                    title: Text(
                      '$tableNumber ${operation.symbol} $multiplier = $result',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}
