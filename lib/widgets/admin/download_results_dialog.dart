import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cbtapp/server/quiz_server.dart';
import 'package:cbtapp/utils/app_colors.dart';
import 'package:cbtapp/utils/csv_helper.dart';
import 'package:cbtapp/utils/path_helper.dart';

class DownloadResultsDialog extends StatefulWidget {
  const DownloadResultsDialog({super.key});

  @override
  State<DownloadResultsDialog> createState() => _DownloadResultsDialogState();
}

class _DownloadResultsDialogState extends State<DownloadResultsDialog> {
  List<Map<String, dynamic>> _sessions = [];
  final Map<String, bool> _selectedSessions = {};
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    try {
      final subjects = QuizServer().getSubjects();

      if (subjects.isEmpty) {
        setState(() {
          _errorMessage = "No exam sessions found. Create a session first.";
          _isLoading = false;
        });
        return;
      }

      // Convert to List<Map<String, dynamic>> safely
      List<Map<String, dynamic>> sessionsList = [];

      subjects.forEach((key, value) {
        sessionsList.add({
          'code': key,
          'title': value.title,
          'students': value.enrolledStudents.length,
          'completed': value.completedStudents.length,
        });
      });

      setState(() {
        _sessions = sessionsList;

        // Add "All Sessions" option
        _sessions.insert(0, {
          'code': 'ALL',
          'title': 'All Sessions Combined',
          'students': 0,
          'completed': 0,
        });

        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading sessions: $e");
      setState(() {
        _errorMessage = "Error loading sessions: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadResults() async {
    final selectedCodes = _selectedSessions.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one session"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final file = File('quiz_results.csv');
      if (!await file.exists()) {
        throw Exception(
          "No results file found. No exams have been submitted yet.",
        );
      }

      final csvString = await file.readAsString();
      if (csvString.trim().isEmpty) {
        throw Exception(
          "Results file is empty. No exams have been submitted yet.",
        );
      }

      final allRows = CsvHelper.parseCsv(csvString).map((row) {
        // Convert List<dynamic> to List<String> safely
        return (row as List).map((e) => e?.toString() ?? '').toList();
      }).toList();

      if (allRows.isEmpty) {
        throw Exception("No results data found");
      }

      // Check if there's only header row (no data)
      if (allRows.length <= 1) {
        throw Exception("No exam results available yet");
      }

      final header = allRows.first;
      final dataRows = allRows.skip(1).toList();

      // Filter by selected sessions
      List<List<String>> filteredRows;
      String filename;

      if (selectedCodes.contains('ALL')) {
        filteredRows = dataRows;
        filename =
            "All_Sessions_Results_${DateTime.now().millisecondsSinceEpoch}.csv";
      } else {
        filteredRows = dataRows.where((row) {
          if (row.length < 5) return false;
          final subject = row.length > 4 ? row[4] : ''; // Subject is at index 4
          return selectedCodes.contains(subject);
        }).toList();

        if (filteredRows.isEmpty) {
          throw Exception("No results found for the selected session(s)");
        }

        if (selectedCodes.length == 1) {
          final session = _sessions.firstWhere(
            (s) => s['code'] == selectedCodes.first,
            orElse: () => {'title': selectedCodes.first},
          );
          filename =
              "${session['title']}_Results_${DateTime.now().millisecondsSinceEpoch}.csv"
                  .replaceAll(' ', '_');
        } else {
          filename =
              "Selected_Sessions_Results_${DateTime.now().millisecondsSinceEpoch}.csv";
        }
      }

      // Prepare CSV with enhanced format
      final List<List<String>> enhancedData = [
        [
          "S/N",
          "Timestamp",
          "Matric Number",
          "Surname",
          "Firstname",
          "Subject",
          "OBJ Correct",
          "Total OBJ",
          "OBJ Score (%)",
          "TYPED Correct",
          "Total TYPED",
          "TYPED Score (%)",
          "THEORY Answered",
          "Total THEORY",
          "Overall Score (%)",
          "Status",
        ],
      ];

      for (var i = 0; i < filteredRows.length; i++) {
        final row = filteredRows[i];

        // Parse values with proper defaults
        final timestamp = row.isNotEmpty ? row[0] : '';
        final matric = row.length > 1 ? row[1] : '';
        final surname = row.length > 2 ? row[2] : '';
        final firstname = row.length > 3 ? row[3] : '';
        final subject = row.length > 4 ? row[4] : 'UNKNOWN';

        final objCorrect = row.length > 5 ? int.tryParse(row[5]) ?? 0 : 0;
        final totalObj = row.length > 6 ? int.tryParse(row[6]) ?? 0 : 0;
        final typedCorrect = row.length > 7 ? int.tryParse(row[7]) ?? 0 : 0;
        final totalTyped = row.length > 8 ? int.tryParse(row[8]) ?? 0 : 0;
        final theoryAnswered = row.length > 9 ? int.tryParse(row[9]) ?? 0 : 0;
        final totalTheory = row.length > 10 ? int.tryParse(row[10]) ?? 0 : 0;
        final overallScore = row.length > 11
            ? double.tryParse(row[11]) ?? 0
            : 0;

        // Calculate scores
        final objScore = totalObj > 0
            ? ((objCorrect / totalObj) * 100).toStringAsFixed(1)
            : "0.0";

        final typedScore = totalTyped > 0
            ? ((typedCorrect / totalTyped) * 100).toStringAsFixed(1)
            : "0.0";

        enhancedData.add([
          (i + 1).toString(),
          timestamp,
          matric,
          surname,
          firstname,
          subject,
          objCorrect.toString(),
          totalObj.toString(),
          "$objScore%",
          typedCorrect.toString(),
          totalTyped.toString(),
          "$typedScore%",
          theoryAnswered.toString(),
          totalTheory.toString(),
          "${overallScore.toStringAsFixed(1)}%",
          overallScore >= 50 ? "PASS" : "FAIL",
        ]);
      }

      // Write to file
      final downloadsDir = await PathHelper.getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception("Downloads folder not found");
      }

      // Ensure filename is safe
      filename = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      final filePath = PathHelper.join(downloadsDir, filename);
      final outputFile = File(filePath);
      await outputFile.writeAsString(CsvHelper.listToCsv(enhancedData));

      if (!mounted) return;

      Navigator.pop(context); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Results exported to Downloads/\n$filename"),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: "OPEN FOLDER",
            textColor: Colors.white,
            onPressed: () async {
              final dir = await PathHelper.getDownloadsDirectory();
              if (dir != null) {
                Process.run('explorer.exe', [dir]);
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              const Text(
                "Download Failed",
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "OK",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: const Text(
        "Download Results",
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w400,
        ),
      ),
      content: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // const SizedBox(height: 24),
                    // ElevatedButton(
                    //   onPressed: () => Navigator.pop(context),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: AppColors.darkPrimary,
                    //   ),
                    //   child: const Text("CLOSE"),
                    // ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select sessions to download",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final isSelected =
                            _selectedSessions[session['code']] ?? false;

                        return CheckboxListTile(
                          title: Text(
                            session['title'],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          subtitle: session['code'] != 'ALL'
                              ? Text(
                                  "Completed: ${session['completed']}/${session['students']}",
                                  style: TextStyle(color: AppColors.textMuted),
                                )
                              : Text(
                                  "Download all sessions in one file",
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (session['code'] == 'ALL') {
                                // If "All Sessions" is selected, clear others
                                _selectedSessions.clear();
                                if (value == true) {
                                  _selectedSessions['ALL'] = true;
                                }
                              } else {
                                if (value == true) {
                                  // If selecting a specific session, deselect "All Sessions"
                                  _selectedSessions.remove('ALL');
                                  _selectedSessions[session['code']] = true;
                                } else {
                                  _selectedSessions.remove(session['code']);
                                }
                              }
                            });
                          },
                          activeColor: AppColors.success,
                          checkColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: _errorMessage == null
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "CANCEL",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: _isDownloading ? null : _downloadResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("DOWNLOAD"),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "CLOSE",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
    );
  }
}
