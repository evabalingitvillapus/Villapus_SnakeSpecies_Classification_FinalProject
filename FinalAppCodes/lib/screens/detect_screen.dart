import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/classifier_provider.dart' as cp;
import '../providers/history_provider.dart';
import '../models/history_item.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key, this.imagePath, this.results});

  final String? imagePath;
  final List<Map<String, dynamic>>? results;

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  String? _imagePath;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.imagePath != null) {
      _imagePath = widget.imagePath;
    }
    if (widget.results != null) {
      _results = widget.results!;
    }
  }

  Future<void> _pick(ImageSource src) async {
    setState(() => _loading = true);
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: src, imageQuality: 85);
    if (!mounted) return;
    if (xfile == null) {
      setState(() => _loading = false);
      return;
    }

    final file = File(xfile.path);
    final classifierProv = Provider.of<cp.ClassifierProvider>(
      context,
      listen: false,
    );
    final hp = Provider.of<HistoryProvider>(context, listen: false);

    final saved = await classifierProv.saveImageToAppDir(file);
    final results = await classifierProv.classifyFile(saved);

    final top = results.isNotEmpty
        ? results.first
        : {'label': 'Unknown', 'confidence': 0.0};
    final item = HistoryItem(
      label: top['label'],
      confidence: (top['confidence'] as double),
      imagePath: saved.path,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await hp.add(item);

    setState(() {
      _imagePath = saved.path;
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detect')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Image area with floating camera/gallery buttons
            SizedBox(
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imagePath!),
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: double.infinity,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No image',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_imagePath != null)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _loading
                      ? const Center(
                          key: ValueKey('loading'),
                          child: CircularProgressIndicator(),
                        )
                      : ListView.separated(
                          key: const ValueKey('results'),
                          itemCount: _results.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, i) {
                            final r = _results[i];
                            final conf = (r['confidence'] as double) * 100;
                            return ListTile(
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text(r['label']),
                              trailing: Text('${conf.toStringAsFixed(1)}%'),
                            );
                          },
                        ),
                ),
              ),
            const SizedBox(height: 12),
            if (_imagePath != null)
              ElevatedButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Camera'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pick(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Gallery'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pick(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.camera),
                label: const Text('Classify another'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            const SizedBox(height: 12),

            Row(
              children: [
                if (_imagePath != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _imagePath = null;
                      _results = [];
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
