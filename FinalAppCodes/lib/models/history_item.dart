class HistoryItem {
  final int? id;
  final String label;
  final double confidence;
  final String imagePath;
  final int timestamp;

  HistoryItem({
    this.id,
    required this.label,
    required this.confidence,
    required this.imagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'confidence': confidence,
      'imagePath': imagePath,
      'timestamp': timestamp,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> m) => HistoryItem(
    id: m['id'] as int?,
    label: m['label'] as String,
    confidence: m['confidence'] as double,
    imagePath: m['imagePath'] as String,
    timestamp: m['timestamp'] as int,
  );
}
