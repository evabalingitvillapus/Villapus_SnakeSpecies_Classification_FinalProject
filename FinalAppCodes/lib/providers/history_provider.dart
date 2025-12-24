import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/history_item.dart';

class HistoryProvider extends ChangeNotifier {
  Database? _db;
  List<HistoryItem> items = [];
  Future<void> init() async {
    try {
      final path = join(await getDatabasesPath(), 'history.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
        CREATE TABLE history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          label TEXT,
          confidence REAL,
          imagePath TEXT,
          timestamp INTEGER
        )
      ''');
        },
      );
      await _loadAll();
    } catch (e) {
      // In test / host environments sqflite may not be initialized for the
      // platform. Avoid crashing tests; continue with empty in-memory history.
      // ignore: avoid_print
      print('HistoryProvider.init: could not open DB: $e');
      _db = null;
      items = [];
      notifyListeners();
    }
  }

  Future<void> _loadAll() async {
    if (_db == null) return;
    final rows = await _db!.query('history', orderBy: 'timestamp DESC');
    items = rows.map((r) => HistoryItem.fromMap(r)).toList();
    notifyListeners();
  }

  Map<String, double> classPercentages() {
    if (items.isEmpty) return {};
    final counts = <String, int>{};
    for (final it in items) {
      counts[it.label] = (counts[it.label] ?? 0) + 1;
    }
    final total = items.length;
    return counts.map((k, v) => MapEntry(k, v / total * 100));
  }

  Future<void> add(HistoryItem item) async {
    if (_db == null) {
      // DB unavailable (e.g. tests); keep history in-memory.
      items.insert(
        0,
        HistoryItem(
          id: null,
          label: item.label,
          confidence: item.confidence,
          imagePath: item.imagePath,
          timestamp: item.timestamp,
        ),
      );
      notifyListeners();
      return;
    }
    final id = await _db!.insert('history', item.toMap());
    items.insert(
      0,
      HistoryItem(
        id: id,
        label: item.label,
        confidence: item.confidence,
        imagePath: item.imagePath,
        timestamp: item.timestamp,
      ),
    );
    notifyListeners();
  }

  Future<void> clear() async {
    if (_db == null) {
      items.clear();
      notifyListeners();
      return;
    }
    await _db!.delete('history');
    items.clear();
    notifyListeners();
  }
}
