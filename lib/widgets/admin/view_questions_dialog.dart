import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';
import 'package:cbtapp/widgets/admin/edit_question_dialog.dart';
import 'dart:io';
import 'package:cbtapp/utils/csv_helper.dart';

class ViewQuestionsDialog extends StatefulWidget {
  final String subjectCode;
  final String subjectTitle;

  const ViewQuestionsDialog({
    super.key,
    required this.subjectCode,
    required this.subjectTitle,
  });

  @override
  State<ViewQuestionsDialog> createState() => _ViewQuestionsDialogState();
}

class _ViewQuestionsDialogState extends State<ViewQuestionsDialog> {
  List<List<dynamic>> _questions = [];
  bool _isLoading = true;
  String? _error;
  String? _questionBankFile;

  @override
  void initState() {
    super.initState();
    _questionBankFile = 'questions_${widget.subjectCode.toLowerCase()}.csv';
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final file = File(_questionBankFile!);
      if (!await file.exists()) {
        setState(() {
          _isLoading = false;
          _questions = [];
        });
        return;
      }

      final csvString = await file.readAsString();
      print("📄 Loading CSV, length: ${csvString.length}");

      final allRows = CsvHelper.parseCsv(csvString);

      setState(() {
        if (allRows.isNotEmpty) {
          // Check if first row is header
          if (allRows[0][0].toString().toLowerCase() == 'type') {
            _questions = allRows.sublist(1);
          } else {
            _questions = allRows;
          }

          // Ensure each question has at least 8 columns
          for (var i = 0; i < _questions.length; i++) {
            while (_questions[i].length < 8) {
              _questions[i].add(''); // Pad with empty strings
            }
          }

          // Log image data for debugging
          int imageCount = 0;
          for (var i = 0; i < _questions.length; i++) {
            if (_questions[i].length > 7 &&
                _questions[i][7].toString().isNotEmpty) {
              imageCount++;
              final imgData = _questions[i][7].toString();
              print(
                "📸 Question ${i + 1} has image data: ${imgData.substring(0, math.min(50, imgData.length))}...",
              );
            }
          }

          print(
            "📚 Loaded ${_questions.length} questions ($imageCount with images)",
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading questions: $e");
      setState(() {
        _error = "Error loading questions: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUpdatedQuestion(
    int index,
    Map<String, dynamic> updatedQuestion,
  ) async {
    try {
      print(
        "💾 Saving question ${index + 1} with image: ${updatedQuestion['imageBase64'] != null}",
      );

      // Ensure all values are Strings
      final List<String> updatedRow = [
        updatedQuestion['type']?.toString() ?? 'OBJ',
        updatedQuestion['text']?.toString() ?? '',
        updatedQuestion['optionA']?.toString() ?? '',
        updatedQuestion['optionB']?.toString() ?? '',
        updatedQuestion['optionC']?.toString() ?? '',
        updatedQuestion['optionD']?.toString() ?? '',
        updatedQuestion['answer']?.toString() ?? '',
        updatedQuestion['imageBase64']?.toString() ??
            '', // Image column - critical!
      ];

      // Update the local list
      setState(() {
        _questions[index] = updatedRow;
      });

      // Save to CSV file with headers
      final file = File(_questionBankFile!);

      // Create all rows with proper typing
      final List<List<String>> allRows = [
        ["Type", "Text", "OptA", "OptB", "OptC", "OptD", "Answer", "Image"],
        ..._questions
            .map((row) => row.map((e) => e.toString()).toList())
            ,
      ];

      // Convert to CSV with proper escaping
      final csvContent = CsvHelper.listToCsv(allRows);

      // Write to file
      await file.writeAsString(csvContent);

      // Verify the write
      final savedContent = await file.readAsString();
      print("✅ Saved CSV length: ${savedContent.length}");

      // Check if image data is in the saved file
      if (updatedQuestion['imageBase64'] != null) {
        final imageData = updatedQuestion['imageBase64'] as String;
        print("📸 Image data length in save: ${imageData.length}");

        // Verify the image data is in the CSV
        if (savedContent.contains(
          imageData.substring(0, math.min(50, imageData.length)),
        )) {
          print("✅ Image data verified in CSV");
        } else {
          print("❌ Image data NOT found in CSV - possible corruption");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Question ${index + 1} updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("❌ Error saving question: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving question: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildQuestionImage(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      // Handle both full data URI and raw base64
      String cleanBase64 = imageBase64;
      if (imageBase64.contains('base64,')) {
        cleanBase64 = imageBase64.split('base64,').last;
      }

      // Remove any whitespace or invalid characters
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s'), '');

      // Check if it's a valid base64 string (multiple of 4 length)
      if (cleanBase64.length % 4 != 0) {
        cleanBase64 = cleanBase64.padRight(
          cleanBase64.length + (4 - cleanBase64.length % 4),
          '=',
        );
      }

      final bytes = base64Decode(cleanBase64);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            height: 150,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print("❌ Image error: $error");
              return Container(
                height: 150,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.grey[600],
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Image could not be loaded",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print("❌ Error decoding image: $e");
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withAlpha(77)),
          color: Colors.red.withAlpha(26),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text("Invalid image data", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Row(
        children: [
          Icon(Icons.quiz, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Questions - ${widget.subjectTitle}",
              style: const TextStyle(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 900,
        height: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : _questions.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      color: AppColors.textMuted,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No questions found for this session",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Import questions using the 'Import Questions' option",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.darkPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Total Questions: ${_questions.length}",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Click ✏️ to edit",
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final q = _questions[index];
                        final type = q[0].toString();
                        final question = q[1].toString();

                        // Check if there's an image (8th column, index 7)
                        String? imageBase64;
                        if (q.length > 7 && q[7].toString().isNotEmpty) {
                          imageBase64 = q[7].toString();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: type == 'OBJ'
                                          ? Colors.blue.withAlpha(26)
                                          : type == 'TYPED'
                                          ? Colors.orange.withAlpha(26)
                                          : Colors.purple.withAlpha(26),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        color: type == 'OBJ'
                                            ? Colors.blue
                                            : type == 'TYPED'
                                            ? Colors.orange
                                            : Colors.purple,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Q${index + 1}",
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  // Edit button
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: AppColors.darkPrimary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // Convert List to Map for editing
                                      final questionMap = {
                                        'type': type,
                                        'text': question,
                                        'optionA': q.length > 2
                                            ? q[2].toString()
                                            : '',
                                        'optionB': q.length > 3
                                            ? q[3].toString()
                                            : '',
                                        'optionC': q.length > 4
                                            ? q[4].toString()
                                            : '',
                                        'optionD': q.length > 5
                                            ? q[5].toString()
                                            : '',
                                        'answer': q.length > 6
                                            ? q[6].toString()
                                            : '',
                                        'imageBase64': imageBase64,
                                      };

                                      showDialog(
                                        context: context,
                                        builder: (ctx) => EditQuestionDialog(
                                          question: questionMap,
                                          questionNumber: index + 1,
                                          onSave: (updatedQuestion) {
                                            _saveUpdatedQuestion(
                                              index,
                                              updatedQuestion,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    tooltip: 'Edit Question',
                                  ),
                                ],
                              ),

                              // Display image if present
                              if (imageBase64 != null && imageBase64.isNotEmpty)
                                _buildQuestionImage(imageBase64),

                              const SizedBox(height: 12),
                              Text(
                                question,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              if (type == 'OBJ' && q.length >= 7) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _buildOptionChip('A', q[2].toString()),
                                    _buildOptionChip('B', q[3].toString()),
                                    _buildOptionChip('C', q[4].toString()),
                                    _buildOptionChip('D', q[5].toString()),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withAlpha(26),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Answer: ${q[6].toString().toUpperCase()}",
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (type == 'TYPED' && q.length >= 7) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withAlpha(26),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.keyboard,
                                        size: 14,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Correct Answer: ${q[6]}",
                                        style: TextStyle(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "CLOSE",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (_questions.isNotEmpty)
          ElevatedButton(
            onPressed: _exportQuestions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text("EXPORT CSV"),
          ),
      ],
    );
  }

  Future<void> _exportQuestions() async {
    // Show export options
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Export Questions",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          "Choose export format:",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportAsCSV();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPrimary,
            ),
            child: const Text("CSV"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportAsJSON();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text("JSON"),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsCSV() async {
    // Create a copy with headers
    final List<List<dynamic>> exportData = [
      ["Type", "Text", "OptA", "OptB", "OptC", "OptD", "Answer"],
      ..._questions.map((row) => row.sublist(0, math.min(7, row.length))),
    ];

    final csvContent = CsvHelper.listToCsv(exportData);

    // Save to file
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${widget.subjectCode}_questions_$timestamp.csv';

      // You can add file picker here to let user choose location
      final file = File(fileName);
      await file.writeAsString(csvContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Questions exported to $fileName"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error exporting: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAsJSON() async {
    // Convert to JSON format
    final List<Map<String, dynamic>> jsonData = [];

    for (var q in _questions) {
      jsonData.add({
        'type': q[0].toString(),
        'text': q[1].toString(),
        'optionA': q.length > 2 ? q[2].toString() : '',
        'optionB': q.length > 3 ? q[3].toString() : '',
        'optionC': q.length > 4 ? q[4].toString() : '',
        'optionD': q.length > 5 ? q[5].toString() : '',
        'answer': q.length > 6 ? q[6].toString() : '',
      });
    }

    final jsonString = jsonEncode(jsonData);

    // Save to file
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${widget.subjectCode}_questions_$timestamp.json';

      final file = File(fileName);
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Questions exported to $fileName"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error exporting: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOptionChip(String letter, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkPrimary.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkPrimary,
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
