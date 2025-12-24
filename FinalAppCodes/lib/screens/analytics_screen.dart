import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/history_provider.dart';
import '../providers/class_provider.dart';
import '../models/history_item.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _showErrorsOnly = false;
  // Confidence threshold for considering an entry an "error" (50%).
  final double _errorThreshold = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Consumer2<HistoryProvider, ClassProvider>(
          builder: (context, history, classes, _) {
            // Apply filter based on the "Show errors only" toggle.
            final allItems = history.items;
            final items = _showErrorsOnly
                ? allItems.where((i) => i.confidence < _errorThreshold).toList()
                : List<HistoryItem>.from(allItems);

            // Recompute percentages and metrics using filtered items
            final counts = <String, int>{};
            final sumConf = <String, double>{};
            for (final it in items) {
              counts[it.label] = (counts[it.label] ?? 0) + 1;
              sumConf[it.label] = (sumConf[it.label] ?? 0.0) + it.confidence;
            }
            final total = items.length;
            final overall = total == 0
                ? 0.0
                : (items
                              .map((e) => e.confidence)
                              .fold<double>(0.0, (p, n) => p + n) /
                          total) *
                      100;
            final errorRate = (100 - overall).clamp(0.0, 100.0);
            // compute per-class average confidence (as percentage)
            final perClassAccuracy = <String, double>{};
            counts.forEach((k, v) {
              final sum = sumConf[k] ?? 0.0;
              perClassAccuracy[k] = v == 0 ? 0.0 : (sum / v * 100);
            });

            // dashboard cards
            Widget card(String title, String value, {Color? color}) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color ?? Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // per-class row
            Widget buildClassRow(String label, double pct) {
              dynamic cp;
              try {
                cp = classes.classes.firstWhere((c) => c.name == label);
              } catch (_) {
                cp = null;
              }
              final color = cp?.color ?? Colors.grey;
              final count = counts[label] ?? 0;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Detections: $count',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Accuracy',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      total == 0 ? '--' : '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            final entries = perClassAccuracy.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // filter / toggle row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // allow quick reset to show all
                          if (_showErrorsOnly) {
                            setState(() => _showErrorsOnly = false);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.view_list),
                              const SizedBox(width: 8),
                              Text(_showErrorsOnly ? 'Errors' : 'All'),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Text('Show errors only'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showErrorsOnly,
                            onChanged: (v) =>
                                setState(() => _showErrorsOnly = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // metric cards 2x2
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.8,
                    children: [
                      card('Total Detections', '$total'),
                      card(
                        'Overall Accuracy',
                        '${overall.toStringAsFixed(1)}%',
                      ),
                      card(
                        'Verification Rate',
                        '${overall.toStringAsFixed(1)}%',
                        color: Colors.green,
                      ),
                      card(
                        'Error Rate',
                        '${errorRate.toStringAsFixed(1)}%',
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Daily activity chart placeholder
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 7-day bar chart using history
                        SizedBox(
                          height: 160,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // compute counts per day for last 7 days
                              final now = DateTime.now();
                              final days = List.generate(
                                7,
                                (i) => DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                ).subtract(Duration(days: 6 - i)),
                              );
                              // use filtered items (errors-only toggle) for daily counts
                              final counts = days.map((d) {
                                final start = d.millisecondsSinceEpoch;
                                final end = DateTime(
                                  d.year,
                                  d.month,
                                  d.day,
                                  23,
                                  59,
                                  59,
                                ).millisecondsSinceEpoch;
                                return items
                                    .where(
                                      (it) =>
                                          it.timestamp >= start &&
                                          it.timestamp <= end,
                                    )
                                    .length
                                    .toDouble();
                              }).toList();

                              final maxCount = counts.isEmpty
                                  ? 1.0
                                  : (counts
                                        .reduce((a, b) => a > b ? a : b)
                                        .clamp(1.0, double.infinity));

                              return BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (maxCount * 1.4),
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= days.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final label = [
                                            'Mon',
                                            'Tue',
                                            'Wed',
                                            'Thu',
                                            'Fri',
                                            'Sat',
                                            'Sun',
                                          ][days[idx].weekday - 1];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        },
                                        reservedSize: 28,
                                        interval: 1,
                                      ),
                                    ),
                                  ),
                                  gridData: FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(counts.length, (i) {
                                    final value = counts[i];
                                    return BarChartGroupData(
                                      x: i,
                                      barsSpace: 6,
                                      barRods: [
                                        BarChartRodData(
                                          toY: value,
                                          width: (constraints.maxWidth / 20)
                                              .clamp(6.0, 18.0),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          color: i == counts.length - 1
                                              ? Colors.blueAccent
                                              : Colors.blue.shade200,
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                                duration: const Duration(milliseconds: 300),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Per-Class Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // per-class list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return buildClassRow(e.key, e.value);
                    },
                  ),

                  const SizedBox(height: 56),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
