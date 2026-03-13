import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cbtapp/server/quiz_server.dart';
import 'package:cbtapp/utils/app_colors.dart';

class LiveLogSection extends StatefulWidget {
  const LiveLogSection({super.key});

  @override
  State<LiveLogSection> createState() => _LiveLogSectionState();
}

class _LiveLogSectionState extends State<LiveLogSection> {
  final List<String> _activityLog = [];
  Timer? _logTimer;
  final QuizServer _quizServer = QuizServer(); // Get the instance

  @override
  void initState() {
    super.initState();
    _logTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateActivityLog();
    });
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    super.dispose();
  }

  void _updateActivityLog() {
    // Use static property through the class
    final clients = QuizServer.connectedClients;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (clients.isNotEmpty) {
      for (var client in clients) {
        if (!_activityLog.contains('$timeStr - $client')) {
          setState(() {
            _activityLog.add('$timeStr - $client');
            if (_activityLog.length > 50) {
              _activityLog.removeAt(0);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withAlpha(128), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              gradient: LinearGradient(
                colors: [AppColors.surfaceLight, AppColors.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      "Live Activity Log",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimary.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.darkPrimary.withAlpha(77),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_alt,
                        size: 14,
                        color: AppColors.darkPrimary,
                      ),
                      const SizedBox(width: 6),
                      StreamBuilder<List<String>>(
                        stream: _quizServer.studentStream,
                        initialData:
                            QuizServer.connectedClients, // Use static property
                        builder: (context, snapshot) {
                          final clients = snapshot.data ?? [];
                          final activeCount = clients
                              .where((c) => !c.contains("FINISHED"))
                              .length;
                          return Text(
                            "$activeCount Active",
                            style: TextStyle(
                              color: AppColors.darkPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          SizedBox(
            height: 250,
            child: StreamBuilder<List<String>>(
              stream: _quizServer.studentStream,
              initialData: QuizServer.connectedClients, // Use static property
              builder: (context, snapshot) {
                final clients = snapshot.data ?? [];

                if (clients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                        // const SizedBox(height: 8),
                        Text(
                          "No Active Students",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Waiting for students to connect...",
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: clients.length,
                    itemBuilder: (ctx, i) {
                      final client = clients[i];
                      final isFinished = client.contains("FINISHED");

                      // Extract matric - handle different formats
                      String matric = client.split(" ")[0];
                      String studentName = client;

                      if (client.contains(" - FINISHED ✅")) {
                        studentName = client.replaceAll(" - FINISHED ✅", "");
                      } else if (client.contains(" - Progress:")) {
                        final parts = client.split(" - Progress:");
                        studentName = parts[0];
                      }

                      String? progress;
                      if (client.contains("Progress:")) {
                        final parts = client.split("Progress:");
                        progress = parts.last.trim();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isFinished
                              ? AppColors.success.withAlpha(26)
                              : AppColors.surfaceLight.withAlpha(204),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFinished
                                ? AppColors.success.withAlpha(77)
                                : AppColors.darkPrimary.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFinished
                                    ? AppColors.success.withAlpha(26)
                                    : AppColors.darkPrimary.withAlpha(26),
                              ),
                              child: Center(
                                child: Icon(
                                  isFinished
                                      ? Icons.check_circle
                                      : Icons.radio_button_checked,
                                  color: isFinished
                                      ? AppColors.success
                                      : AppColors.darkPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    matric,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (progress != null) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timeline,
                                          size: 12,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Progress: $progress",
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Text(
                                      isFinished ? "Completed" : "In Progress",
                                      style: TextStyle(
                                        color: isFinished
                                            ? AppColors.success
                                            : AppColors.darkPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: AppColors.textSecondary,
                              ),
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppColors.border),
                              ),
                              onSelected: (value) {
                                if (value == 'force_logout') {
                                  _showForceLogoutDialog(matric, studentName);
                                } else if (value == 'allow_retake') {
                                  _showAllowRetakeDialog(matric, studentName);
                                } else if (value == 'manage_subjects') {
                                  _showManageStudentSubjects(
                                    matric,
                                    studentName,
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'force_logout',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Force Logout'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'allow_retake',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Allow Retake'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'manage_subjects',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.book,
                                        size: 18,
                                        color: AppColors.darkPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Manage Subjects',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showForceLogoutDialog(String matric, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            const Text(
              "Force Logout Student?",
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          "Remove $studentName ($matric) from active session?\n\nThey will be immediately logged out and cannot continue.",
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
              _quizServer.forceLogout(matric); // Use instance method
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ $studentName has been force logged out"),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text("FORCE LOGOUT"),
          ),
        ],
      ),
    );
  }

  void _showAllowRetakeDialog(String matric, String studentName) {
    // Get subjects the student has completed
    final completedSubjects = _quizServer.getStudentCompletedSubjects(
      matric,
    ); // Use instance method

    if (completedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This student has no completed exams"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedSubject;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.refresh, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text(
              "Allow Exam Retake?",
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select subject to allow retake for $studentName:",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSubject,
                  hint: const Text("Select Subject"),
                  isExpanded: true,
                  items: completedSubjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (value) {
                    Navigator.pop(ctx);
                    if (value != null) {
                      _confirmRetake(matric, studentName, value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRetake(String matric, String studentName, String subjectCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Confirm Retake",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          "Allow $studentName to retake $subjectCode?\n\nThis will reset their completion status.",
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
              _quizServer.allowRetake(
                matric,
                subjectCode,
              ); // Use instance method
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ $studentName can now retake $subjectCode"),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text("ALLOW RETAKE"),
          ),
        ],
      ),
    );
  }

  void _showManageStudentSubjects(String matric, String studentName) {
    // Get available subjects
    final availableSubjects = _quizServer.getSubjects().keys.toList();

    // Get current enrolled subjects
    final enrolledSubjects = _quizServer.getStudentEnrolledSubjects(
      matric,
    ); // Use instance method

    Map<String, bool> selectedSubjects = {};
    for (var subject in availableSubjects) {
      selectedSubjects[subject] = enrolledSubjects.contains(subject);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          "Manage Subjects for $studentName",
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 400),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select subjects this student can take:",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (availableSubjects.isEmpty)
                    const Text(
                      "No active exam sessions. Create sessions first.",
                      style: TextStyle(color: AppColors.warning),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: availableSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = availableSubjects[index];
                          final session = _quizServer.getSubjects()[subject];
                          return CheckboxListTile(
                            title: Text(
                              "${session?.title} ($subject)",
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              "Duration: ${session?.duration} mins",
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            value: selectedSubjects[subject] ?? false,
                            onChanged: (value) {
                              setState(() {
                                selectedSubjects[subject] = value ?? false;
                              });
                            },
                            activeColor: AppColors.success,
                            checkColor: Colors.white,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
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
              final selected = selectedSubjects.entries
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .toList();
              _quizServer.enrollStudentInSubjects(
                matric,
                selected,
              ); // Use instance method
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ Subjects updated for $studentName"),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }
}
