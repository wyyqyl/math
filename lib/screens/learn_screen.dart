import 'package:flutter/material.dart';
import 'package:math/models/operation_model.dart';
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
    return 'Learn ${operation.name}';
  }

  @override
  Widget build(BuildContext context) {
    // Create a sorted copy of the list to ensure tables are displayed in order.
    final sortedTables = List<int>.from(settings.selectedTables)..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF38ef7d), Color(0xFF11998e)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedTables.length,
          itemBuilder: (context, index) {
            final tableNumber = sortedTables[index];
            return Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      const Color(0xFF38ef7d).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ExpansionTile(
                  initiallyExpanded: index == 0,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11998e).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.book_rounded,
                      size: 30,
                      color: const Color(0xFF11998e),
                    ),
                  ),
                  title: Text(
                    'Table of $tableNumber',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF11998e),
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
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? const Color(0xFF38ef7d).withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF11998e),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          '$tableNumber ${operation.symbol} $multiplier = $result',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF11998e),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF38ef7d),
                          size: 28,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
