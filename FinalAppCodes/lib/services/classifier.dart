import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;

class Classifier {
  late Interpreter _interpreter;
  late List<String> labels;
  late int inputSize;
  bool available = false;

  Future<void> loadModelAndLabels() async {
    try {
      final modelData = await rootBundle.load('assets/model_unquant.tflite');
      _interpreter = Interpreter.fromBuffer(modelData.buffer.asUint8List());

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      labels = labelsData
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final input = _interpreter.getInputTensor(0);
      final shape = input.shape; // e.g. [1,224,224,3]
      inputSize = shape.length >= 3 ? shape[1] : 224;
      available = true;
    } catch (e) {
      // If the native TFLite library isn't available (common in tests/host),
      // mark classifier as unavailable instead of throwing.
      // ignore: avoid_print
      print('Classifier.loadModelAndLabels: failed to load model: $e');
      available = false;
    }
  }

  Future<List<Map<String, dynamic>>> classifyImage(File imageFile) async {
    if (!available) return [];

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;

    // center-crop to square, then resize to model input size (avoids distortion)
    final cropSize = image.width < image.height ? image.width : image.height;
    final cropX = (image.width - cropSize) ~/ 2;
    final cropY = (image.height - cropSize) ~/ 2;
    final cropped = img.copyCrop(image, cropX, cropY, cropSize, cropSize);
    final resized = img.copyResize(
      cropped,
      width: inputSize,
      height: inputSize,
    );

    // helper to run inference with a given normalization function
    List<double> runWithNorm(double Function(int) normPixel) {
      // prepare input tensor as nested List: [1][inputSize][inputSize][3]
      var input = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (_) => List.generate(inputSize, (_) => List.filled(3, 0.0)),
        ),
      );

      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final px = resized.getPixel(x, y);
          input[0][y][x][0] = normPixel(img.getRed(px));
          input[0][y][x][1] = normPixel(img.getGreen(px));
          input[0][y][x][2] = normPixel(img.getBlue(px));
        }
      }

      final outputShape = _interpreter
          .getOutputTensor(0)
          .shape; // e.g. [1, num_labels]
      final output = List.generate(
        outputShape[0],
        (_) => List.filled(outputShape[1], 0.0),
      );

      _interpreter.run(input, output);
      return (output[0] as List).cast<double>();
    }

    // convert raw scores to probabilities; if scores already sum to ~1.0, use them
    List<double> toProb(List<double> scores) {
      final sum = scores.fold<double>(0.0, (p, e) => p + e);
      if (sum > 0.999 && sum < 1.001) return scores;
      // apply softmax
      final max = scores.reduce((a, b) => a > b ? a : b);
      final exps = scores.map((s) => math.exp(s - max)).toList();
      final expsSum = exps.fold<double>(0.0, (p, e) => p + e);
      if (expsSum == 0.0) return List<double>.filled(scores.length, 0.0);
      return exps.map((e) => e / expsSum).toList();
    }

    // first try normalization 0..1 (pixel / 255)
    final scores01 = runWithNorm((int v) => v / 255.0);
    var probs = toProb(scores01);

    // if top probability is low, try alternative normalization (-1..1)
    final topProb = probs.isNotEmpty
        ? probs.reduce((a, b) => a > b ? a : b)
        : 0.0;
    if (topProb < 0.6) {
      final scoresNorm = runWithNorm((int v) => (v / 255.0 - 0.5) * 2.0);
      final probsNorm = toProb(scoresNorm);
      final topNorm = probsNorm.isNotEmpty
          ? probsNorm.reduce((a, b) => a > b ? a : b)
          : 0.0;
      if (topNorm > topProb + 0.05) {
        // prefer the normalization that yields higher top probability
        probs = probsNorm;
      }
    }

    // Debug: report top label and confidence
    final topVal = probs.isNotEmpty
        ? probs.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final topIdx = probs.indexOf(topVal);
    final topLabel = (topIdx >= 0 && topIdx < labels.length)
        ? labels[topIdx]
        : 'unknown';
    // ignore: avoid_print
    print('Classifier top: $topLabel ($topVal) [labels=${labels.length}]');

    List<Map<String, dynamic>> results = [];
    for (int i = 0; i < labels.length && i < probs.length; i++) {
      results.add({'label': labels[i], 'confidence': probs[i]});
    }

    results.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );
    return results;
  }
}
