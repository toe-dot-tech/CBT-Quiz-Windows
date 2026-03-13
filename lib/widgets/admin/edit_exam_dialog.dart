import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';

class EditExamDialog extends StatefulWidget {
  final Map<String, dynamic> session;
  final Function(String, String, int, int) onSave;

  const EditExamDialog({
    super.key,
    required this.session,
    required this.onSave,
  });

  @override
  State<EditExamDialog> createState() => _EditExamDialogState();
}

class _EditExamDialogState extends State<EditExamDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _questionLimitController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.session['code']);
    _titleController = TextEditingController(text: widget.session['title']);
    _durationController = TextEditingController(
      text: widget.session['duration'].toString(),
    );
    _questionLimitController = TextEditingController(
      text: widget.session['questionLimit'].toString(),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _durationController.dispose();
    _questionLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: const Text(
        "Edit Exam Session",
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(
              _codeController,
              "Subject Code",
              Icons.code,
              enabled: false,
            ),
            const SizedBox(height: 12),
            _buildField(_titleController, "Course Title", Icons.book),
            const SizedBox(height: 12),
            _buildField(
              _durationController,
              "Duration (minutes)",
              Icons.timer,
            ),
            const SizedBox(height: 12),
            _buildField(
              _questionLimitController,
              "Question Limit",
              Icons.list,
            ),
          ],
        ),
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
            widget.onSave(
              _codeController.text.trim(),
              _titleController.text.trim(),
              int.tryParse(_durationController.text) ?? 30,
              int.tryParse(_questionLimitController.text) ?? 40,
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: const Text("UPDATE SESSION"),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.surfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? AppColors.border : AppColors.border.withAlpha(128),
        ),
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? AppColors.textSecondary : AppColors.textMuted,
          ),
          prefixIcon: Icon(icon, color: AppColors.darkPrimary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}