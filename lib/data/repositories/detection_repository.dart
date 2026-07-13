import 'dart:io';

import '../local/csv_store.dart';
import '../models/detection_result.dart';

/// Everything screens need from the local detection log. This is the
/// ONLY class that should ever call into [CsvStore] — UI code talks
/// to this repository, never to the CSV file directly.
class DetectionRepository {
  DetectionRepository({CsvStore? store}) : _store = store ?? CsvStore.instance;

  final CsvStore _store;

  Future<int> saveDetection(DetectionResult result) => _store.insert(result);

  Future<List<DetectionResult>> getRecentDetections({int limit = 50}) {
    return _store.getAll(limit: limit);
  }

  Future<void> clearAll() => _store.clearAll();

  Future<void> deleteDetection(int id) => _store.deleteById(id);

  /// Returns the CSV file backing the whole log, ready to hand to
  /// `share_plus` for the "Export CSV" action.
  Future<File> exportCsvFile() => _store.exportFile();
}
