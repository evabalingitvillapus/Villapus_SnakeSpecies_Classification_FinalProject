# Snake Species Classifier

This app loads a Teachable Machine TFLite model and `labels.txt` from `assets/` and provides:

- Camera and Gallery classification
- History of classifications (stored locally)
- Per-class distribution chart (from history)
- Class Info list (reads `labels.txt`)
- Evaluate mode: pick multiple images to compute per-class accuracy (expects filenames like `label_*.jpg`)

Getting started

1. Ensure `assets/model_unquant.tflite` and `assets/labels.txt` are present (already included here).
2. Install dependencies:

```bash
flutter pub get
```

3. Run on a device:

```bash
flutter run
```

Evaluation notes

- To compute accuracy with the `Evaluate` screen, pick a batch of images where each image filename starts with the expected label followed by an underscore. For example: `cat_001.jpg`, `dog_002.jpg`.
- The app will compute per-class accuracy and display percentages.

Improving accuracy

- If you need >=95% accuracy on 6 classes, provide labeled test images for those classes.
- Many factors influence accuracy (image quality, model training, labels). If accuracy is low, consider retraining your model with more examples or augmentations.

If you want, I can help run evaluations with your sample images and tune preprocessing to try to reach the target accuracy for 6 classes.
