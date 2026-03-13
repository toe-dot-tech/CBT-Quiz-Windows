import 'dart:async';
import 'dart:io';
import 'package:cbtapp/server/quiz_server.dart';
import 'package:cbtapp/services/result_storage_service.dart';
import 'package:cbtapp/utils/app_colors.dart';
import 'package:cbtapp/utils/csv_helper.dart';
import 'package:cbtapp/utils/docs_helper.dart';
import 'package:cbtapp/utils/file_picker_helper.dart';
import 'package:cbtapp/widgets/add_student_dialog.dart';
import 'package:cbtapp/widgets/admin/download_results_dialog.dart';
import 'package:cbtapp/widgets/admin/edit_exam_dialog.dart';
import 'package:cbtapp/widgets/admin/import_dialog.dart';
import 'package:cbtapp/widgets/confirm_dialog.dart';
import 'package:cbtapp/widgets/developer_credit_container.dart';
import 'package:cbtapp/widgets/session_card.dart';
import 'package:cbtapp/widgets/student_list_dialog.dart';
import 'package:cbtapp/widgets/trend_chart.dart';
import 'package:cbtapp/widgets/admin/live_log_section.dart';
import 'package:cbtapp/widgets/admin/stats_cards.dart';
import 'package:cbtapp/widgets/admin/view_questions_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});
  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView>
    with SingleTickerProviderStateMixin {
  bool isLive = false;
  String ip = "Offline";

  int passedCount = 0;
  int failedCount = 0;
  String avgScore = "0%";
  Timer? _refreshTimer;
  String _submissionStatus = "0 / 0";

  // Removed _registeredData and _uploadedQuestions since they're session-based now
  int _totalStudents = 0;

  final _courseController = TextEditingController(text: "Library Science");
  final _timerController = TextEditingController(text: "20");
  final _qCountController = TextEditingController(text: "35");

  // Subject management controllers
  final _subjectCodeController = TextEditingController(text: "MATH101");
  final _subjectTitleController = TextEditingController(
    text: "Mathematics 101",
  );
  final _subjectDurationController = TextEditingController(text: "30");
  final _subjectQuestionLimitController = TextEditingController(text: "40");

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final ResultStorageService resultService = ResultStorageService();

  List<int> _passTrendData = [];
  List<int> _failTrendData = [];
  List<String> _trendLabels = [];
  Timer? _trendUpdateTimer;

  List<Map<String, dynamic>> _availableSessions = [];

  @override
  void initState() {
    super.initState();

    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadStats();
    });

    QuizServer().studentStream.listen((clients) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _loadStats();
        });
      }
    });

    QuizServer().subjectUpdateStream.listen((_) {
      if (mounted) {
        _loadAvailableSessions();
      }
    });

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeTrendData();
    _trendUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateTrendData();
    });

    _loadAvailableSessions();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _courseController.dispose();
    _timerController.dispose();
    _qCountController.dispose();
    _subjectCodeController.dispose();
    _subjectTitleController.dispose();
    _subjectDurationController.dispose();
    _subjectQuestionLimitController.dispose();
    _trendUpdateTimer?.cancel();
    _pulseController.dispose();

    super.dispose();
  }

  void _initializeTrendData() {
    _passTrendData = [0, 0, 0, 0, 0, 0];
    _failTrendData = [0, 0, 0, 0, 0, 0];
    _trendLabels = ['-5m', '-4m', '-3m', '-2m', '-1m', 'now'];
  }

  void _updateTrendData() {
    setState(() {
      if (_passTrendData.length >= 20) {
        _passTrendData.removeAt(0);
        _failTrendData.removeAt(0);
        _trendLabels.removeAt(0);
      }
      _passTrendData.add(passedCount);
      _failTrendData.add(failedCount);
      _trendLabels.add('${DateTime.now().minute}:${DateTime.now().second}');
    });
  }

  void _loadAvailableSessions() {
    final subjects = QuizServer().getSubjects();
    setState(() {
      _availableSessions = subjects.entries.map((entry) {
        return {
          'code': entry.key,
          'title': entry.value.title,
          'duration': entry.value.duration,
          'questionLimit': entry.value.questionLimit,
          'students': entry.value.enrolledStudents.length,
          'completed': entry.value.completedStudents.length,
          'questionCount': entry.value.questionCount,
        };
      }).toList();

      // Update total students count
      _totalStudents = QuizServer().getStudents().length;
    });
  }

  void _showAddStudentToSessionDialog(String subjectCode, String subjectTitle) {
    final allStudents = QuizServer()
        .getStudents()
        .values
        .map(
          (student) => {
            'matric': student.matric,
            'surname': student.surname,
            'firstname': student.firstname,
            'class': student.studentClass ?? 'N/A',
          },
        )
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AddStudentToSessionDialog(
        subjectCode: subjectCode,
        subjectTitle: subjectTitle,
        allStudents: allStudents,
        onAdd: (matric, surname, firstname, studentClass) {
          _saveSingleStudentToSession(
            subjectCode,
            matric,
            surname,
            firstname,
            studentClass,
          );
        },
      ),
    );
  }

  Future<void> _saveSingleStudentToSession(
    String subjectCode,
    String matric,
    String surname,
    String firstname,
    String studentClass,
  ) async {
    try {
      final matricUpper = matric.trim().toUpperCase();
      print("📝 Adding student $matricUpper to session $subjectCode");

      // Check if student exists in main registry
      final allStudents = QuizServer().getStudents();
      if (!allStudents.containsKey(matricUpper)) {
        // Add to main registry first
        print("➕ Adding new student to main registry: $matricUpper");
        QuizServer().addStudentToRegistry(
          matric: matricUpper,
          surname: surname,
          firstname: firstname,
          studentClass: studentClass.isEmpty ? "Not Specified" : studentClass,
        );
      }

      // Enroll student in session - this should update both student and subject
      print("📚 Enrolling $matricUpper in subject: $subjectCode");
      QuizServer().enrollStudentInSubjects(matricUpper, [subjectCode]);

      // Force a reload of sessions to reflect changes
      _loadAvailableSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Student $matricUpper added to $subjectCode"),
            backgroundColor: AppColors.success,
          ),
        );
      }

      print("✅ Successfully added student to session");
    } catch (e) {
      print("❌ Error in _saveSingleStudentToSession: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding student: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showViewEnrolledStudentsDialog(
    String subjectCode,
    String subjectTitle,
  ) {
    final subject = QuizServer().getSubjects()[subjectCode];
    if (subject == null) return;

    final enrolledMatrics = subject.enrolledStudents;
    final students = QuizServer().getStudents();

    List<Map<String, dynamic>> enrolledStudents = [];
    for (var matric in enrolledMatrics) {
      final student = students[matric];
      if (student != null) {
        enrolledStudents.add({
          'matric': student.matric,
          'name': "${student.surname} ${student.firstname}",
          'class': student.studentClass ?? 'N/A',
        });
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StudentListDialog(
        subjectCode: subjectCode,
        subjectTitle: subjectTitle,
        students: enrolledStudents,
        onExport: () {
          // TODO: Implement export functionality
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Export feature coming soon"),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  void _showViewQuestionsDialog(String subjectCode, String subjectTitle) {
    showDialog(
      context: context,
      builder: (ctx) => ViewQuestionsDialog(
        subjectCode: subjectCode,
        subjectTitle: subjectTitle,
      ),
    );
  }

  void _showRemoveSessionDialog(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: "Remove Session?",
        message: "This will permanently delete:",
        items: [
          "Session: ${session['title']} (${session['code']})",
          "Question bank: questions_${session['code'].toLowerCase()}.csv",
          "All student enrollments for this session",
        ],
        onConfirm: () async {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const AlertDialog(
              backgroundColor: AppColors.surfaceLight,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Removing session..."),
                ],
              ),
            ),
          );

          QuizServer().removeExamSession(session['code']);

          if (context.mounted) Navigator.pop(context);
          _loadAvailableSessions();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅ Session ${session['code']} removed"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        confirmColor: AppColors.error,
      ),
    );
  }

  void _showEditExamDialog(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (ctx) => EditExamDialog(
        session: session,
        onSave: (code, title, duration, questionLimit) {
          QuizServer().editExamSession(
            subjectCode: code,
            courseTitle: title,
            duration: duration,
            questionLimit: questionLimit,
          );
          _loadAvailableSessions();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Session updated for $code"),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _showClearAllSessionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: "Clear All Sessions?",
        message: "This will PERMANENTLY DELETE:",
        items: [
          "All exam session files (questions_*.csv)",
          "All subject data and enrollments",
          "Student subject assignments",
        ],
        onConfirm: () async {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const AlertDialog(
              backgroundColor: AppColors.surfaceLight,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Clearing all sessions..."),
                ],
              ),
            ),
          );

          QuizServer().clearAllSessions();

          if (context.mounted) Navigator.pop(context);
          _loadAvailableSessions();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ All sessions cleared successfully"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        confirmColor: AppColors.error,
      ),
    );
  }

  void _showBulkImportStudentsDialog(String subjectCode, String subjectTitle) {
    showDialog(
      context: context,
      builder: (ctx) => ImportStudentsDialog(
        subjectCode: subjectCode,
        subjectTitle: subjectTitle,
        onSelectFile: () => _importStudentsForSubject(subjectCode),
      ),
    );
  }

  Future<void> _importStudentsForSubject(String subjectCode) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Selecting CSV file..."),
            ],
          ),
        ),
      );

      final file = await FilePickerHelper.pickCsvFile();

      if (context.mounted) Navigator.pop(context);

      if (file == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No file selected"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceLight,
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Importing students..."),
              ],
            ),
          ),
        );
      }

      final result = await QuizServer().importStudentsFromCsv(
        file,
        subjectCode,
      );

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        String message;
        Color color;

        if (result['added'] > 0) {
          message =
              "✅ Import complete!\n"
              "Added: ${result['added']} new students\n"
              "Already enrolled: ${result['existing']}\n"
              "Failed: ${result['failed']}";
          color = Colors.green;
        } else {
          message =
              "⚠️ No new students added.\n"
              "Already enrolled: ${result['existing']}\n"
              "Failed: ${result['failed']}";
          color = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: const Duration(seconds: 6),
          ),
        );
      }

      _loadAvailableSessions();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        _showErrorDialog("Error importing students: $e");
      }
    }
  }

  void _importQuestionsForSubject(String subjectCode) {
    showDialog(
      context: context,
      builder: (ctx) => ImportQuestionsDialog(
        subjectCode: subjectCode,
        subjectTitle: subjectCode,
        onSelectFile: () => _processSubjectQuestions(subjectCode),
      ),
    );
  }

  Future<void> _processSubjectQuestions(String subjectCode) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Selecting file..."),
            ],
          ),
        ),
      );

      final file = await FilePickerHelper.pickDocxFile();

      if (context.mounted) Navigator.pop(context);

      if (file == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No file selected"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Processing DOCX file..."),
              ],
            ),
          ),
        );
      }

      final questions = await DocxHelper.extractQuestionsFromDocx(file);

      if (context.mounted) Navigator.pop(context);

      if (questions.isNotEmpty) {
        // Count how many questions have images
        int imagesCount = questions
            .where((q) => q['imageBase64'] != null)
            .length;

        await _saveQuestionsToSubjectCsv(questions, subjectCode);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "✅ Questions imported for $subjectCode!\n"
                "Questions: ${questions.length} ($imagesCount with images)",
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (context.mounted) {
          _showErrorDialog(
            "Failed to extract questions from DOCX file.\n"
            "Please ensure the file is properly formatted.",
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        _showErrorDialog("Error importing file: $e");
      }
    }
  }

  Future<void> _saveQuestionsToSubjectCsv(
    List<Map<String, dynamic>> questions,
    String subjectCode,
  ) async {
    final questionBankFile = 'questions_${subjectCode.toLowerCase()}.csv';
    final file = File(questionBankFile);

    // Check if file exists to determine if we need header
    final bool fileExists = await file.exists();

    final List<List<dynamic>> csvRows = [];

    for (var q in questions) {
      csvRows.add([
        q['type'] ?? 'OBJ',
        _escapeCsvField(q['text'] ?? ''),
        _escapeCsvField(q['optionA'] ?? ''),
        _escapeCsvField(q['optionB'] ?? ''),
        _escapeCsvField(q['optionC'] ?? ''),
        _escapeCsvField(q['optionD'] ?? ''),
        _escapeCsvField(q['answer'] ?? ''),
        _escapeCsvField(q['imageBase64'] ?? ''), // CRITICAL: Add image column
      ]);
    }

    if (!fileExists) {
      // New file - write header with Image column
      String header = "Type,Text,OptA,OptB,OptC,OptD,Answer,Image\n";
      String csvData = CsvHelper.listToCsv(csvRows);
      await file.writeAsString(header + csvData);
      print("📝 Created new question bank with Image column for $subjectCode");
    } else {
      // Append to existing file
      String csvData = CsvHelper.listToCsv(csvRows);
      await file.writeAsString(
        "\n$csvData",
        mode: FileMode.append,
        flush: true,
      );
      print("📝 Appended to existing question bank for $subjectCode");
    }

    // Count images saved
    int imageCount = questions.where((q) => q['imageBase64'] != null).length;
    print("✅ Saved ${questions.length} questions to $questionBankFile");
    print("📸 Questions with images saved: $imageCount/${questions.length}");

    // Update question count in server
    QuizServer().updateQuestionCount(subjectCode, questions.length);
  }

  Widget _buildAvailableSessionsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Exam Sessions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  // IconButton(
                  //   icon: Icon(Icons.add_circle, color: AppColors.success),
                  //   onPressed: _showCreateExamDialog,
                  //   tooltip: "Create Exam Session",
                  // ),
                  if (_availableSessions.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_sweep, color: AppColors.error),
                      onPressed: _showClearAllSessionsDialog,
                      tooltip: "Clear all sessions",
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom sessions
          if (_availableSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No exam sessions created yet",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Click the 'Create Exam Session' to create your first session",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            StreamBuilder<void>(
              stream: QuizServer().subjectUpdateStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadAvailableSessions();
                  });
                }

                //I wrapped with sized box so the lsit buildr can be scrollable
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _availableSessions.length,
                    itemBuilder: (context, index) {
                      final session = _availableSessions[index];
                      return SessionCard(
                        session: session,
                        onEdit: () => _showEditExamDialog(session),
                        onViewStudents: () => _showViewEnrolledStudentsDialog(
                          session['code'],
                          session['title'],
                        ),
                        onViewQuestions: () => _showViewQuestionsDialog(
                          session['code'],
                          session['title'],
                        ),
                        onAddStudent: () => _showAddStudentToSessionDialog(
                          session['code'],
                          session['title'],
                        ),
                        onImportQuestions: () =>
                            _importQuestionsForSubject(session['code']),
                        onImportStudents: () => _showBulkImportStudentsDialog(
                          session['code'],
                          session['title'],
                        ),
                        onRemove: () => _showRemoveSessionDialog(session),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _loadStats() async {
    final stats = await ResultStorageService().calculateLiveStats();

    final resultsFile = File('quiz_results.csv');
    int finishedCount = 0;
    if (await resultsFile.exists()) {
      final lines = await resultsFile.readAsLines();
      finishedCount = lines.where((l) => l.trim().isNotEmpty).length - 1;
    }

    if (mounted) {
      setState(() {
        passedCount = stats.passed;
        failedCount = stats.failed;
        _submissionStatus =
            "${finishedCount < 0 ? 0 : finishedCount} / $_totalStudents";
        avgScore = "${stats.avgScore.toStringAsFixed(1)}%";
      });
    }
  }

  void _showCreateExamDialog() {
    _subjectCodeController.clear();
    _subjectTitleController.clear();
    _subjectDurationController.clear();
    _subjectQuestionLimitController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Create Exam Session",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _entryField(
                _subjectCodeController,
                "Subject Code (e.g., MATH101)",
                Icons.code,
              ),
              const SizedBox(height: 12),
              _entryField(_subjectTitleController, "Course Title", Icons.book),
              const SizedBox(height: 12),
              _entryField(
                _subjectDurationController,
                "Duration (minutes)",
                Icons.timer,
              ),
              const SizedBox(height: 12),
              _entryField(
                _subjectQuestionLimitController,
                "Question Limit",
                Icons.list,
              ),
            ],
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
            onPressed: _createExamSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text("CREATE SESSION"),
          ),
        ],
      ),
    );
  }

  void _createExamSession() {
    QuizServer().createExamSession(
      subjectCode: _subjectCodeController.text.trim(),
      courseTitle: _subjectTitleController.text.trim(),
      duration: int.tryParse(_subjectDurationController.text) ?? 30,
      questionLimit: int.tryParse(_subjectQuestionLimitController.text) ?? 40,
    );

    Navigator.pop(context);
    _loadAvailableSessions();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Exam session created for ${_subjectCodeController.text}\n"
          "Question bank: questions_${_subjectCodeController.text.toLowerCase()}.csv",
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _escapeCsvField(String field) {
    // Base64 strings are long and may contain special characters
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.length > 100) {
      // Escape quotes by doubling them and wrap in quotes
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Error", style: TextStyle(color: AppColors.error)),
        content: Text(message, style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _executeKillSwitch() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Executing Kill Switch...",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              "Resetting all systems",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      if (isLive) {
        await QuizServer().stop();
      }

      setState(() {
        passedCount = 0;
        failedCount = 0;
        avgScore = "0%";
        _submissionStatus = "0 / 0";
        _passTrendData = [0, 0, 0, 0, 0];
        _failTrendData = [0, 0, 0, 0, 0];
        _trendLabels = ['-5m', '-4m', '-3m', '-2m', 'now'];
        isLive = false;
        ip = "Offline";
      });

      // Clear results file
      final resultsFile = File('quiz_results.csv');
      if (await resultsFile.exists()) {
        await resultsFile.writeAsString(
          "Timestamp,Matric,Surname,Firstname,Subject,Obj Correct,Total Obj,Typed Correct,Total Typed,Theory Answered,Total Theory,Score(%)\n",
        );
      }

      // Clear all exam sessions and student data
      QuizServer()
          .clearAllSessions(); // This already clears subjects and student enrollments

      // Also clear registered_students.csv file
      final registeredFile = File('registered_students.csv');
      if (await registeredFile.exists()) {
        await registeredFile.writeAsString("Matric,Surname,Firstname,Class\n");
      }

      // Clear any leftover session CSV files
      final directory = Directory.current;
      final files = directory.listSync();
      for (var file in files) {
        if (file is File) {
          final filename = file.path.split(Platform.pathSeparator).last;
          // Delete any questions_*.csv files that might be left
          if (filename.startsWith('questions_') && filename.endsWith('.csv')) {
            try {
              await file.delete();
              print("🗑️ Deleted leftover file: $filename");
            } catch (e) {
              print("⚠️ Could not delete $filename: $e");
            }
          }
        }
      }

      // Clear student list in server
      QuizServer().clearStudentList();

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Kill Switch Executed",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "All systems, files, and data have been reset",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      _loadAvailableSessions();
      print("✅ Kill switch executed successfully - all data cleared");
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error executing kill switch: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
      print("❌ Kill switch error: $e");
    }
  }

  void _confirmKillSwitch() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: "⚠️ KILL SWITCH",
        message: "This will RESET EVERYTHING:",
        items: [
          "Clear all statistics (pass/fail counts, averages)",
          "Reset performance trend",
          "Clear submission status",
          "Remove all exam sessions",
          "Clear student registry",
          "Stop server if running",
        ],
        onConfirm: _executeKillSwitch,
        confirmColor: AppColors.error,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ADMIN DASHBOARD",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  isLive ? "SERVER LIVE: " : "SERVER OFFLINE",
                  style: TextStyle(
                    color: isLive ? AppColors.success : AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLive) ...[
                  SelectableText(
                    "http://$ip:8080",
                    style: const TextStyle(
                      color: AppColors.darkAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    color: AppColors.darkAccent,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: "http://$ip:8080"));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Address copied to clipboard"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
        Row(
          children: [
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withAlpha(51),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _confirmKillSwitch,
                icon: const Icon(Icons.power_settings_new, size: 20),
                label: const Text("KILL SWITCH"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(width: 0.2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                'CBT',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                'Computer Based Test',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _sidebarItem(Icons.dashboard, "Dashboard", true),
          // Removed Exam Config, Create Exam Session, Add Single Question, Import Question DOCX
          // Add Single Student, Bulk Student Upload from sidebar
          _sidebarItem(
            Icons.add_box_rounded,
            "Create Exam Session",
            false,
            onTap: () => _showCreateExamDialog(),
          ),
          _sidebarItem(
            Icons.assessment,
            "Download Results",
            false,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => const DownloadResultsDialog(),
              );
            },
          ),
          const Spacer(),
          buildCreditCard(context: context),
          _serverControlPanel(),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String label,
    bool active, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? AppColors.darkPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? AppColors.surface : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serverControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLive ? AppColors.error : AppColors.pass,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () async {
          try {
            if (isLive) {
              print("Stopping server...");
              await QuizServer().stop();
              if (mounted) {
                setState(() {
                  isLive = false;
                  ip = "Offline";
                });
              }
              print("Server stopped");
            } else {
              print("Starting server...");
              final address = await QuizServer().start();
              print("Server started at: $address");
              if (mounted) {
                setState(() {
                  ip = address;
                  isLive = true;
                });
              }
            }
          } catch (e) {
            print("Server error: $e");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Server error: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Text(
          isLive ? "STOP EXAM" : "START EXAM",
          style: const TextStyle(
            color: AppColors.surfaceLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _entryField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        style: const TextStyle(color: AppColors.darkPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: AppColors.darkPrimary),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.darkPrimary),
          ),
          disabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      child: Column(
        children: [
          const SizedBox(height: 32),
          TrendChart(
            passData: _passTrendData.isEmpty
                ? [0, 0, 0, 0, 0, 0]
                : _passTrendData,
            failData: _failTrendData.isEmpty
                ? [0, 0, 0, 0, 0, 0]
                : _failTrendData,
            labels: _trendLabels.isEmpty
                ? ['-5m', '-4m', '-3m', '-2m', '-1m', 'now']
                : _trendLabels,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalStudents = QuizServer().getStudents().length;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 632,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              StatsCards(
                                registeredCount: totalStudents,
                                finishedCount: passedCount + failedCount,
                                avgScore: avgScore,
                                // In _buildAvailableSessionsSection method, update the fold function
                                totalQuestions: _availableSessions.fold<int>(
                                  0,
                                  (sum, session) =>
                                      sum +
                                      ((session['questionCount'] as num?)
                                              ?.toInt() ??
                                          0),
                                ),
                                submissionStatus: _submissionStatus,
                              ),
                              _buildTrendChart(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 26),
                        SizedBox(
                          width: 300,
                          child: Column(
                            children: [
                              // Exam Sessions Section (replaces default sections)
                              _buildAvailableSessionsSection(),
                              const LiveLogSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Default Question Bank Section Removed
                  // Registered Students Section Removed
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
