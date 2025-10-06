import 'package:flutter/material.dart';
import 'settings_model.dart';

class SettingsScreen extends StatefulWidget {
  final List<int> initialSelectedTables;
  final int initialQuizDuration;
  final int initialAdditionSubtractionLimit;

  const SettingsScreen({
    super.key,
    required this.initialSelectedTables,
    required this.initialQuizDuration,
    required this.initialAdditionSubtractionLimit,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<int> _selectedTables;
  late int _quizDuration;
  late int _additionSubtractionLimit;

  @override
  void initState() {
    super.initState();
    _selectedTables = List.from(widget.initialSelectedTables);
    _quizDuration = widget.initialQuizDuration;
    _additionSubtractionLimit = widget.initialAdditionSubtractionLimit;
  }

  void _toggleTable(int tableNumber) {
    setState(() {
      if (_selectedTables.contains(tableNumber)) {
        _selectedTables.remove(tableNumber);
      } else {
        _selectedTables.add(tableNumber);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedTables = [2, 3, 4, 5, 6, 7, 8, 9];
    });
  }

  void _clearAll() {
    setState(() {
      _selectedTables = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic _) async {
        if (!didPop) {
          if (_selectedTables.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please select at least one table before going back.',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
          Navigator.of(context).pop(
            AppSettings(
              selectedTables: _selectedTables,
              quizDuration: _quizDuration,
              additionSubtractionLimit: _additionSubtractionLimit,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.orangeAccent,
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).maybePop(
                AppSettings(
                  selectedTables: _selectedTables,
                  quizDuration: _quizDuration,
                  additionSubtractionLimit: _additionSubtractionLimit,
                ),
              );
            },
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.yellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildWideLayout();
                } else {
                  return _buildNarrowLayout();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTablesCard(),
          const SizedBox(height: 20),
          _buildAdditionSubtractionCard(),
          const SizedBox(height: 20),
          _buildQuizSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _buildTablesCard()),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildQuizSettingsCard(),
                const SizedBox(height: 20),
                _buildAdditionSubtractionCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multiplication Tables',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.0,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                final tableNumber = index + 2;
                final isSelected = _selectedTables.contains(tableNumber);
                return InkWell(
                  onTap: () => _toggleTable(tableNumber),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(15.0),
                      border: isSelected
                          ? Border.all(color: Colors.orange.shade800, width: 4)
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '$tableNumber',
                        style: TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.orange.shade800
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Select All'),
                ),
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionSubtractionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Addition & Subtraction Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Number Limit', style: TextStyle(fontSize: 18)),
                Text(
                  '<= $_additionSubtractionLimit',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _additionSubtractionLimit.toDouble(),
              min: 10,
              max: 100,
              divisions: 9,
              label: _additionSubtractionLimit.round().toString(),
              activeColor: Colors.orange,
              inactiveColor: Colors.orange.shade100,
              onChanged: (double value) {
                setState(() {
                  _additionSubtractionLimit = value.round();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Duration', style: TextStyle(fontSize: 18)),
                Text(
                  '${_quizDuration.round()} seconds',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _quizDuration.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              label: _quizDuration.round().toString(),
              activeColor: Colors.orange,
              inactiveColor: Colors.orange.shade100,
              onChanged: (double value) {
                setState(() {
                  _quizDuration = value.round();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
