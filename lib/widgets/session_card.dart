import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onEdit;
  final VoidCallback onViewStudents;
  final VoidCallback onAddStudent;
  final VoidCallback onImportQuestions;
  final VoidCallback onImportStudents;
  final VoidCallback onViewQuestions;
  final VoidCallback onRemove;

  const SessionCard({
    super.key,
    required this.session,
    required this.onEdit,
    required this.onViewStudents,
    required this.onAddStudent,
    required this.onImportQuestions,
    required this.onImportStudents,
    required this.onViewQuestions,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Session icon with first letter
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                session['code'][0],
                style: TextStyle(
                  color: AppColors.darkPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Session details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${session['title']} (${session['code']})",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildInfoChip(
                      icon: Icons.timer,
                      label: "${session['duration']} mins",
                      color: AppColors.textSecondary,
                    ),
                    _buildInfoChip(
                      icon: Icons.people,
                      label: "${session['students']} enrolled",
                      color: AppColors.textSecondary,
                    ),
                    _buildInfoChip(
                      icon: Icons.check_circle,
                      label: "${session['completed']} completed",
                      color: AppColors.success,
                    ),
                    _buildInfoChip(
                      icon: Icons.quiz,
                      label: "${session['questionCount'] ?? 0} questions",
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Three-dot menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.surfaceLight,
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'view_students':
                  onViewStudents();
                  break;
                case 'add_student':
                  onAddStudent();
                  break;
                case 'import_questions':
                  onImportQuestions();
                  break;
                case 'import_students':
                  onImportStudents();
                  break;
                case 'view_questions':
                  onViewQuestions();
                  break;
                case 'remove':
                  onRemove();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_questions',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Import Questions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_students',
                child: Row(
                  children: [
                    Icon(Icons.group_add, size: 18, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Bulk Import Students'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_student',
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Add Single Student'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit Session'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_questions',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 18, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('View Questions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_students',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 18, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('View Enrolled Students'),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove Session'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
