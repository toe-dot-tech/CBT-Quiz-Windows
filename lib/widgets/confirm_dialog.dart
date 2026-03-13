import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<String> items;
  final VoidCallback onConfirm;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.items,
    required this.onConfirm,
    this.confirmColor = AppColors.error,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Row(
        children: [
          Icon(Icons.warning, color: confirmColor, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text("• $item", style: TextStyle(color: AppColors.textSecondary)),
          )),
          const SizedBox(height: 16),
          Text(
            "This action cannot be undone!",
            style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold),
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
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: const Text("CONFIRM"),
        ),
      ],
    );
  }
}