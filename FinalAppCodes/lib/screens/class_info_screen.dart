import 'dart:io';

import 'package:flutter/material.dart';
import '../models/snake_species_class.dart';
import 'package:flutter/services.dart';

class ClassInfoScreen extends StatefulWidget {
  /// If [cactusClass] is provided, this screen shows details for that class.
  /// Otherwise it falls back to listing labels from `assets/labels.txt`.
  const ClassInfoScreen({super.key, this.cactusClass});

  final CactusClass? cactusClass;

  @override
  State<ClassInfoScreen> createState() => _ClassInfoScreenState();
}

class _ClassInfoScreenState extends State<ClassInfoScreen> {
  List<String> labels = [];

  @override
  void initState() {
    super.initState();
    if (widget.cactusClass == null) _loadLabels();
  }

  Future<void> _loadLabels() async {
    final text = await rootBundle.loadString('assets/labels.txt');
    setState(() {
      labels = text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cc = widget.cactusClass;
    return Scaffold(
      appBar: AppBar(title: Text(cc?.name ?? 'Class Info')),
      body: cc != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE6FB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: cc.hasImage
                            ? ClipOval(
                                child: cc.isAssetImage
                                    ? Image.asset(
                                        cc.effectiveImage!,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(cc.effectiveImage!),
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : Icon(
                                cc.icon,
                                size: 48,
                                color: Theme.of(context).primaryColor,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(cc.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(cc.description),
                ],
              ),
            )
          : ListView.builder(
              itemCount: labels.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(labels[i]),
                subtitle: const Text(
                  'No additional info. Tap to add notes (coming soon).',
                ),
              ),
            ),
    );
  }
}
