import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';
import 'package:cbtapp/utils/csv_helper.dart';

class QuestionBankSection extends StatefulWidget {
  final VoidCallback onRefresh;
  final VoidCallback onWipe;

  const QuestionBankSection({
    super.key,
    required this.onRefresh,
    required this.onWipe,
  });

  @override
  State<QuestionBankSection> createState() => _QuestionBankSectionState();
}

class _QuestionBankSectionState extends State<QuestionBankSection> {
  List<List<dynamic>> _uploadedQuestions = [];
  int _totalQuestionsAvailable = 0;

  @override
  void initState() {
    super.initState();
    _refreshQuestionBank();
  }

  Future<void> _refreshQuestionBank() async {
    try {
      final file = File('questions.csv');
      if (!await file.exists()) {
        setState(() {
          _uploadedQuestions = [];
          _totalQuestionsAvailable = 0;
        });
        return;
      }

      final csvString = await file.readAsString();
      final allRows = CsvHelper.parseCsv(csvString)
          .map((row) => row as List<dynamic>)
          .toList();

      setState(() {
        _uploadedQuestions = allRows;
        if (allRows.isNotEmpty) {
          if (allRows[0][0].toString().toLowerCase() == 'type') {
            _totalQuestionsAvailable = allRows.length - 1;
          } else {
            _totalQuestionsAvailable = allRows.length;
          }
        } else {
          _totalQuestionsAvailable = 0;
        }
      });
    } catch (e) {
      debugPrint("Error refreshing bank: $e");
    }
  }

  List<List<dynamic>> _getDisplayList() {
    if (_uploadedQuestions.isEmpty) return [];
    
    if (_uploadedQuestions[0][0].toString().toLowerCase() == "type") {
      return _uploadedQuestions.sublist(1);
    }
    return _uploadedQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _getDisplayList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Question Bank",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${displayList.length} Questions Loaded",
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onWipe,
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      "Wipe",
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (displayList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No questions found.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 350,
              child: ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (ctx, i) {
                  final qRow = displayList[i];
                  if (qRow.length < 7) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.2,
                        color: AppColors.darkPrimary,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            "${i + 1}.",
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                qRow[1].toString(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "A: ${qRow[2]} | B: ${qRow[3]} | C: ${qRow[4]} | D: ${qRow[5]}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Ans: ${qRow[6]}",
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}