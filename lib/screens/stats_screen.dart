import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:math/managers/profile_manager.dart';
import 'package:math/models/operation_model.dart';
import 'package:math/models/performance_model.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, QuestionPerformance> _performanceData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ProfileManager().loadPerformanceData();
    if (mounted) {
      setState(() {
        _performanceData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: Operation.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
          backgroundColor: Colors.orangeAccent,
          bottom: TabBar(
            tabs: Operation.values.map((op) {
              return Tab(text: op.name);
            }).toList(),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.yellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : TabBarView(
                  children: Operation.values.map((op) {
                    return OperationStatsView(
                      operation: op,
                      performanceData: _performanceData,
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }
}

class OperationStatsView extends StatefulWidget {
  final Operation operation;
  final Map<String, QuestionPerformance> performanceData;

  const OperationStatsView({
    super.key,
    required this.operation,
    required this.performanceData,
  });

  @override
  State<OperationStatsView> createState() => _OperationStatsViewState();
}

class _OperationStatsViewState extends State<OperationStatsView> {
  List<MapEntry<String, QuestionPerformance>> _topTenQuestions = [];
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _updateTopTen();
  }

  void _updateTopTen() {
    final filteredData = widget.performanceData.entries
        .where((entry) => entry.key.contains(widget.operation.symbol))
        .toList();

    filteredData.sort((a, b) => b.value.errorRate.compareTo(a.value.errorRate));

    setState(() {
      _topTenQuestions = filteredData.take(10).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_topTenQuestions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No data available for this operation yet. Practice some more!',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1,
              rotationQuarterTurns: constraints.maxWidth > 600 ? 0 : 1,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey,
                  tooltipHorizontalAlignment: FLHorizontalAlignment.right,
                  tooltipMargin: -200,
                  direction: TooltipDirection.bottom,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = _topTenQuestions[groupIndex];
                    final performance = entry.value;
                    return BarTooltipItem(
                      'Error Rate: ${(performance.errorRate * 100).toStringAsFixed(1)}%\n'
                      'Incorrect: ${performance.timesIncorrect}\n'
                      'Appeared: ${performance.appearanceCount}\n'
                      'Avg Time: ${performance.averageTime.toStringAsFixed(2)}s',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                  });
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= _topTenQuestions.length) {
                        return const Text('');
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _topTenQuestions[index].key.replaceAll(
                            widget.operation.symbol,
                            ' ${widget.operation.symbol} ',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                    reservedSize: 50,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    },
                    interval: 0.2,
                    reservedSize: 42,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _topTenQuestions
                  .asMap()
                  .map(
                    (index, entry) => MapEntry(
                      index,
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.errorRate,
                            color: index == _touchedIndex
                                ? Colors.green
                                : Colors.redAccent,
                            width: 22,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  )
                  .values
                  .toList(),
              gridData: const FlGridData(show: false),
            ),
          ),
        );
      },
    );
  }
}
