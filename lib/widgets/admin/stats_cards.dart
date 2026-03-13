import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';

class StatsCards extends StatelessWidget {
  final int registeredCount;
  final int finishedCount;
  final String avgScore;
  final int totalQuestions;
  final String submissionStatus;

  const StatsCards({
    super.key,
    required this.registeredCount,
    required this.finishedCount,
    required this.avgScore,
    required this.totalQuestions,
    required this.submissionStatus,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 4,
      children: [
        _buildCard("Registered", "$registeredCount", Icons.people, Colors.blue),
        _buildCard(
          "Finished",
          "$finishedCount",
          Icons.check_circle,
          Colors.green,
        ),
        _buildCard("Avg. Score", avgScore, Icons.analytics, Colors.purple),
        _buildCard(
          "Question Bank",
          "$totalQuestions",
          Icons.library_books,
          Colors.orange,
        ),
        _buildCard(
          "Submission Status",
          submissionStatus,
          Icons.check_circle,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(width: 2, color: color)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
         // Container(
          //   padding: const EdgeInsets.all(6),
          //   decoration: BoxDecoration(
          //     color: color.withAlpha(26),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: Icon(icon, size: 16, color: color),
          // ),
          // const SizedBox(width: 8),`
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
