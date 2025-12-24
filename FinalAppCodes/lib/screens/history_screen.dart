import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../widgets/percentage_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hp = Provider.of<HistoryProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(onPressed: hp.clear, icon: const Icon(Icons.delete)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text('Per-class distribution'),
                    SizedBox(height: 8),
                    PercentageChart(data: hp.classPercentages()),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: hp.items.length,
              itemBuilder: (context, i) {
                final it = hp.items[i];
                return ListTile(
                  leading: it.imagePath.isNotEmpty
                      ? Image.file(
                          File(it.imagePath),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : null,
                  title: Text(it.label),
                  subtitle: Text(
                    '${(it.confidence * 100).toStringAsFixed(1)}% • ${DateTime.fromMillisecondsSinceEpoch(it.timestamp)}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
