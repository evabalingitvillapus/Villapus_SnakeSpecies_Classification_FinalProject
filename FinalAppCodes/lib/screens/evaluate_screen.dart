import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/classifier_provider.dart' as cp;

class EvaluateScreen extends StatefulWidget {
  const EvaluateScreen({super.key});

  @override
  State<EvaluateScreen> createState() => _EvaluateScreenState();
}

class _EvaluateScreenState extends State<EvaluateScreen> {
  String _status = '';
  Map<String, int> correct = {};
  Map<String, int> total = {};

  Future<void> _pickAndEvaluate() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (!mounted) return;
    if (images.isEmpty) return;
    setState(() {
      _status = 'Running...';
      correct.clear();
      total.clear();
    });

    final provider = Provider.of<cp.ClassifierProvider>(context, listen: false);

    for (final x in images) {
      final file = File(x.path);
      // assume filename contains label as prefix: label_*.jpg
      final name = file.uri.pathSegments.last;
      final expected = name.split('_').first;
      final res = await provider.classifyFile(file);
      final predicted = res.isNotEmpty ? res.first['label'] as String : '';
      total[expected] = (total[expected] ?? 0) + 1;
      if (predicted == expected) {
        correct[expected] = (correct[expected] ?? 0) + 1;
      }
    }

    setState(() {
      _status = 'Done';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluate Dataset')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickAndEvaluate,
              child: const Text('Pick images and evaluate'),
            ),
            const SizedBox(height: 12),
            Text(_status),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: total.keys.map((k) {
                  final t = total[k] ?? 0;
                  final c = correct[k] ?? 0;
                  final pct = t == 0 ? 0.0 : (c / t * 100);
                  return ListTile(
                    title: Text(k),
                    subtitle: Text('$c / $t (${pct.toStringAsFixed(1)}%)'),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
