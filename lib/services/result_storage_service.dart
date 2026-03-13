import 'dart:async';
import 'dart:io';
import 'package:cbtapp/utils/csv_helper.dart';
import 'package:cbtapp/utils/path_helper.dart';

class ResultStats {
  final int passed;
  final int failed;
  final double avgScore;

  ResultStats({this.passed = 0, this.failed = 0, this.avgScore = 0.0});
}

class ResultStorageService {
  static const String fileName = 'quiz_results.csv';

  Future<ResultStats> calculateLiveStats() async {
    final file = File(fileName);
    if (!await file.exists()) return ResultStats();

    try {
      final csvString = await file.readAsString();
      final fields = CsvHelper.parseCsv(
        csvString,
      ).map((row) => row as List<dynamic>).toList();

      // Skip header
      final dataRows = fields
          .skip(1)
          .where(
            (row) => row.isNotEmpty && row.length >= 11,
          ) // Now expects 11 columns
          .toList();

      if (dataRows.isEmpty) return ResultStats();

      int pass = 0;
      int fail = 0;
      double total = 0;

      for (var row in dataRows) {
        double score =
            double.tryParse(row[10].toString()) ?? 0.0; // Score at index 10
        total += score;
        if (score >= 50.0) {
          pass++;
        } else {
          fail++;
        }
      }

      return ResultStats(
        passed: pass,
        failed: fail,
        avgScore: total / dataRows.length,
      );
    } catch (e) {
      print("Error calculating stats: $e");
      return ResultStats();
    }
  }

  Future<List<Map<String, dynamic>>> loadAllResults() async {
    final file = File(fileName);
    if (!await file.exists()) return [];

    try {
      final csvString = await file.readAsString();
      final rows = CsvHelper.parseCsv(
        csvString,
      ).map((row) => row as List<dynamic>).toList();

      if (rows.length <= 1) return [];
      final dataRows = rows.skip(1).where((row) => row.isNotEmpty).toList();

      return dataRows.map((row) {
        // Handle both old format (5 columns) and new format (11+ columns)
        if (row.length >= 11) {
          return {
            'date': row[0].toString(),
            'matric': row[1].toString(),
            'surname': row[2].toString(),
            'firstname': row[3].toString(),
            'obj_correct': row[4].toString(),
            'total_obj': row[5].toString(),
            'theory_answered': row[6].toString(),
            'total_theory': row[7].toString(),
            'german_answered': row[8].toString(),
            'total_german': row[9].toString(),
            'score': row[10].toString(),
          };
        } else {
          // Old format compatibility
          return {
            'date': row[0].toString(),
            'matric': row[1].toString(),
            'surname': row[2].toString(),
            'firstname': row[3].toString(),
            'obj_correct': '0',
            'total_obj': '0',
            'theory_answered': '0',
            'total_theory': '0',
            'german_answered': '0',
            'total_german': '0',
            'score': row.length > 4 ? row[4].toString() : '0',
          };
        }
      }).toList();
    } catch (e) {
      print("Error loading results: $e");
      return [];
    }
  }

  Future<String> downloadCsvReport(String courseTitle) async {
    try {
      final results = await loadAllResults();
      if (results.isEmpty) return "No results to export";

      // Check if we have detailed data or just simple data
      final bool hasDetailedData =
          results.isNotEmpty &&
          (results.first.containsKey('obj_correct') &&
              int.tryParse(results.first['obj_correct'] ?? '0') != 0);

      List<List<dynamic>> csvData;

      if (hasDetailedData) {
        // Detailed format with OBJ, Theory, German breakdown
        csvData = [
          [
            "S/N",
            "Matric Number",
            "Surname",
            "Firstname",
            "OBJ Correct",
            "Total OBJ",
            "OBJ Score",
            "Theory Answered",
            "Total Theory",
            "German Answered",
            "Total German",
            "Overall %",
            "Status",
          ],
        ];

        for (var i = 0; i < results.length; i++) {
          final r = results[i];
          final objCorrect = int.tryParse(r['obj_correct'] ?? '0') ?? 0;
          final totalObj = int.tryParse(r['total_obj'] ?? '0') ?? 0;
          final objScore = totalObj > 0
              ? ((objCorrect / totalObj) * 100).toStringAsFixed(1)
              : "0.0";
          final overallScore = double.tryParse(r['score'] ?? '0') ?? 0;

          csvData.add([
            i + 1,
            r['matric'],
            r['surname'],
            r['firstname'],
            objCorrect,
            totalObj,
            "$objScore%",
            r['theory_answered'] ?? '0',
            r['total_theory'] ?? '0',
            r['german_answered'] ?? '0',
            r['total_german'] ?? '0',
            "${r['score']}%",
            overallScore >= 50 ? "PASS" : "FAIL",
          ]);
        }
      } else {
        // Simple format (backward compatibility)
        csvData = [
          [
            "S/N",
            "Matric Number",
            "Surname",
            "Firstname",
            "Score (%)",
            "Status",
          ],
        ];

        for (var i = 0; i < results.length; i++) {
          final r = results[i];
          final score = double.tryParse(r['score'] ?? '0') ?? 0;
          csvData.add([
            i + 1,
            r['matric'],
            r['surname'],
            r['firstname'],
            r['score'] ?? '0',
            score >= 50 ? "PASS" : "FAIL",
          ]);
        }
      }

      String csvString = CsvHelper.listToCsv(csvData);

      final downloadsDir = await PathHelper.getDownloadsDirectory();
      if (downloadsDir == null) return "Downloads folder not found";

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String finalPath = PathHelper.join(
        downloadsDir,
        "${courseTitle}_Results_$timestamp.csv",
      );

      final file = File(finalPath);
      await file.writeAsString(csvString);

      return "Successfully exported to Downloads: \n${PathHelper.basename(finalPath)}";
    } catch (e) {
      return "Export failed: $e";
    }
  }

  Future<void> clearAllResults() async {
    final file = File(fileName);
    if (await file.exists()) {
      // Keep header with new format
      await file.writeAsString(
        "Timestamp,Matric,Surname,Firstname,Obj Correct,Total Obj,Theory Answered,Total Theory,German Answered,Total German,Score(%)\n",
      );
    }
  }
}
