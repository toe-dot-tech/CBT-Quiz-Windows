import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';

class ImportQuestionsDialog extends StatelessWidget {
  final String subjectCode;
  final String subjectTitle;
  final VoidCallback onSelectFile;

  const ImportQuestionsDialog({
    super.key,
    required this.subjectCode,
    required this.subjectTitle,
    required this.onSelectFile,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        "Import Questions for $subjectTitle",
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.upload_file,
            size: 60,
            color: AppColors.darkPrimary,
          ),
          const SizedBox(height: 16),
          const Text(
            "Select a DOCX file containing questions.",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Text(
                  "Supported Format:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "1. What is 2+2?\nA. 3\nB. 4\nC. 5\nD. 6\nAns: B",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.darkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "CANCEL",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onSelectFile();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: const Text("SELECT FILE"),
        ),
      ],
    );
  }
}

class ImportStudentsDialog extends StatelessWidget {
  final String subjectCode;
  final String subjectTitle;
  final VoidCallback onSelectFile;

  const ImportStudentsDialog({
    super.key,
    required this.subjectCode,
    required this.subjectTitle,
    required this.onSelectFile,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Text(
        "Import Students for $subjectTitle",
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.upload_file,
            size: 60,
            color: AppColors.darkPrimary,
          ),
          const SizedBox(height: 16),
          const Text(
            "Select a CSV file with student records.",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Text(
                  "CSV Format:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Matric,Surname,Firstname,Class",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.darkPrimary,
                  ),
                ),
                Text(
                  "2024001,OKAFOR,John,SS3",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "CANCEL",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onSelectFile();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: const Text("SELECT FILE"),
        ),
      ],
    );
  }
}