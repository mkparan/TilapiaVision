import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/detection_result.dart';

/// Append-only CSV log of detection results — the entire "database"
/// for this app.
///
/// This replaces an earlier SQLite implementation. Per panel
/// feedback, a relational database was unnecessary overhead for what
/// is, structurally, a single flat log with no joins, no foreign
/// keys, and no queries beyond "give me everything, newest first."
/// A CSV file does that with far less code and — as a direct
/// bonus — doubles as the export format farmers/researchers actually
/// want (opens in Excel/Google Sheets with zero conversion step).
///
/// Screens should never touch this class directly — only
/// [DetectionRepository] does.
class CsvStore {
  CsvStore._internal();
  static final CsvStore instance = CsvStore._internal();

  static const _fileName = 'detection_log.csv';
  static const _converter = ListToCsvConverter();

  File? _file;
  int _nextId = 1;

  Future<File> get _logFile async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, _fileName));
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('${_converter.convert([DetectionResult.csvHeader])}\n');
    }
    _file = file;
    return file;
  }

  Future<int> _peekNextId() async {
    final rows = await _readRows();
    if (rows.isEmpty) return 1;
    final ids = rows.map((r) => int.tryParse(r[0].toString()) ?? 0);
    final maxId = ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  Future<List<List<dynamic>>> _readRows() async {
    final file = await _logFile;
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    const converter = CsvToListConverter(eol: '\n', shouldParseNumbers: false);
    final table = converter.convert(content);
    if (table.isEmpty) return [];
    // Drop the header row, and defensively drop any short/blank
    // trailing row a parser may emit for a final line ending.
    return table.skip(1).where((row) => row.length >= DetectionResult.csvHeader.length).toList();
  }

  Future<int> insert(DetectionResult result) async {
    _nextId = await _peekNextId();
    final row = result.toCsvRow();
    row[0] = _nextId;

    final file = await _logFile;
    final line = _converter.convert([row]);
    await file.writeAsString('$line\n', mode: FileMode.append);
    return _nextId;
  }

  Future<List<DetectionResult>> getAll({int? limit}) async {
    final rows = await _readRows();
    final results = rows.map(DetectionResult.fromCsvRow).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (limit != null && results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  Future<void> clearAll() async {
    final file = await _logFile;
    await file.writeAsString('${_converter.convert([DetectionResult.csvHeader])}\n');
  }

  /// Removes a single row by [id] and rewrites the file. Uses an
  /// explicit '\n' eol on the converter to match every other write
  /// in this class — the default converter eol is '\r\n', which
  /// would silently corrupt every field's trailing character once
  /// read back with the '\n'-configured reader in [_readRows].
  Future<void> deleteById(int id) async {
    final rows = await _readRows();
    final remaining = rows.where((r) => int.tryParse(r[0].toString()) != id).toList();
    final List<List<dynamic>> lines = [DetectionResult.csvHeader, ...remaining];
    const converter = ListToCsvConverter(eol: '\n');
    final file = await _logFile;
    await file.writeAsString('${converter.convert(lines)}\n');
  }

  /// Returns the live log file — used for the "Export CSV" action.
  /// The returned file IS the canonical store, so exporting never
  /// requires generating a second copy.
  Future<File> exportFile() async => _logFile;
}
