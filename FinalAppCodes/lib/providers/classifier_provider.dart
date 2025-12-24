import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../services/classifier.dart';

class ClassifierProvider extends ChangeNotifier {
  final Classifier classifier = Classifier();
  bool initialized = false;

  List<Map<String, dynamic>> lastResults = [];

  Future<void> init() async {
    try {
      await classifier.loadModelAndLabels();
    } catch (e) {
      // Swallow errors when running in test or unsupported host environments.
      // Tests should still be able to pump the widget tree.
      // ignore: avoid_print
      print('ClassifierProvider.init: ignored error $e');
    }
    initialized = true;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> classifyFile(File file) async {
    if (!initialized) await init();
    try {
      final results = await classifier.classifyImage(file);
      lastResults = results;
    } catch (e) {
      // If model isn't available (e.g. running tests or unsupported host),
      // return empty results instead of crashing the app.
      // ignore: avoid_print
      print('ClassifierProvider.classifyFile: classification failed: $e');
      lastResults = [];
    }
    notifyListeners();
    return lastResults;
  }

  Future<File> saveImageToAppDir(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dest = File(
        '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      return await file.copy(dest.path);
    } catch (e) {
      // Fallback for test/host environments where path_provider isn't available.
      final dest = File(
        '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      return await file.copy(dest.path);
    }
  }
}
