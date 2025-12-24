import 'package:flutter/material.dart';

class CactusClass {
  final String name;
  final String description;
  final IconData icon;

  /// Kept for backwards compatibility with older code; prefer `imagePath`.
  final String? asset;

  /// Path to an image. Can be an asset path (starts with 'assets/') or a local file path.
  final String? imagePath;

  CactusClass({
    required this.name,
    required this.description,
    required this.icon,
    this.asset,
    this.imagePath,
  });

  CactusClass copyWith({String? imagePath}) {
    return CactusClass(
      name: name,
      description: description,
      icon: icon,
      asset: asset,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  bool get hasImage =>
      (imagePath != null && imagePath!.isNotEmpty) ||
      (asset != null && asset!.isNotEmpty);
  bool get isAssetImage {
    final path = imagePath ?? asset;
    return path != null && path.startsWith('assets/');
  }

  /// Returns the effective image path preferring `imagePath` over `asset`.
  String? get effectiveImage => imagePath ?? asset;
}
