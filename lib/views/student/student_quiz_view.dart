import 'dart:convert';
import 'package:cbtapp/utils/app_colors.dart';
import 'package:cbtapp/views/student/student_view.dart';
import 'package:http/http.dart' as http;
import 'package:cbtapp/providers/quiz_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentQuizView extends ConsumerStatefulWidget {
  const StudentQuizView({super.key});

  @override
  ConsumerState<StudentQuizView> createState() => _StudentQuizViewState();
}

class _StudentQuizViewState extends ConsumerState<StudentQuizView> {
  final _typedController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    print("📱 StudentQuizView initState");

    // Check for saved progress on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSavedProgress();
    });

    // Listen for quiz state changes
    ref.listen(quizProvider, (QuizState? previous, QuizState next) {
      // Handle manual submission completion
      if (next.questions.isEmpty &&
          next.studentMatric == null &&
          next.studentName == null &&
          previous != null &&
          previous.studentMatric != null) {
        print("🎯 State reset detected - navigating to login");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const StudentView()),
              (route) => false,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Exam submitted successfully!"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    print("🗑️ StudentQuizView dispose");
    _typedController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkForSavedProgress() async {
    print("🔍 Checking for saved progress");
    final state = ref.read(quizProvider);
    if (state.studentMatric != null && state.questions.isEmpty) {
      print("📂 Found saved progress for ${state.studentMatric}");
      final resumed = await ref
          .read(quizProvider.notifier)
          .resumeProgress(state.studentMatric!);
      if (resumed && mounted) {
        print("✅ Progress resumed successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Exam resumed from saved progress"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        print("❌ Failed to resume progress");
      }
    } else {
      print("ℹ️ No saved progress found");
    }
  }

  Future<void> _pingProgress(int index, int total) async {
    final state = ref.read(quizProvider);
    try {
      await http.post(
        Uri.parse('http://${Uri.base.host}:8080/api/progress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matric': state.studentMatric,
          'progress': "${index + 1}/$total",
          'subjectCode':
              state.sessionCode ??
              state.courseTitle.replaceAll(' ', '_').toUpperCase(),
        }),
      );
      print("📡 Progress ping: ${index + 1}/$total");
    } catch (e) {
      debugPrint("Progress ping failed: $e");
    }
  }

  void _handleFinish(BuildContext context, WidgetRef ref) {
    print("🏁 _handleFinish called");

    if (_isSubmitting) {
      print("⚠️ Already submitting, ignoring");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text("Confirm Submission"),
        content: const Text(
          "Are you sure you want to end your exam? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pass),
            onPressed: () async {
              print("✅ User confirmed submission");

              setState(() {
                _isSubmitting = true;
              });

              // Close confirmation dialog
              Navigator.pop(ctx);

              // Show a simple loading indicator (non-dialog)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Submitting your exam..."),
                  duration: Duration(seconds: 30),
                  backgroundColor: AppColors.surfaceLight,
                ),
              );

              print("🚀 Calling submitQuiz()");

              // Submit the quiz
              await ref.read(quizProvider.notifier).submitQuiz();

              print("✅ submitQuiz() completed");

              // Remove the loading snackbar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              // Navigate directly to login screen
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const StudentView()),
                  (route) => false,
                );

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Exam submitted successfully!"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text(
              "SUBMIT EXAM",
              style: TextStyle(color: AppColors.surfaceLight),
            ),
          ),
        ],
      ),
    );
  }

  // Question Navigator Widget
  Widget _buildQuestionNavigator(QuizState state) {
    final totalQuestions = state.questions.length;
    final notifier = ref.read(quizProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QUESTION NAVIGATOR",
          style: TextStyle(
            color: AppColors.surface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Question grid
        SizedBox(
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: totalQuestions,
            itemBuilder: (context, index) {
              final questionNumber = index + 1;
              final status = notifier.getQuestionStatus(index);

              Color boxColor;
              if (status == 'current') {
                boxColor = AppColors.darkPrimary;
              } else if (status == 'answered') {
                boxColor = AppColors.success;
              } else {
                boxColor = AppColors.surfaceLight;
              }

              return GestureDetector(
                onTap: () => notifier.jumpToQuestion(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(8),
                    border: status == 'current'
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: status == 'current'
                        ? [
                            BoxShadow(
                              color: AppColors.darkPrimary.withAlpha(128),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      questionNumber.toString(),
                      style: TextStyle(
                        color: status == 'unanswered'
                            ? AppColors.textSecondary
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Legend
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLegendItem(AppColors.darkPrimary, "Current"),
            const SizedBox(width: 12),
            _buildLegendItem(AppColors.success, "Answered"),
            const SizedBox(width: 12),
            _buildLegendItem(AppColors.surfaceLight, "Unanswered"),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.surface.withAlpha(204),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // Build image widget with fixed dimensions to prevent rebuilds
  Widget _buildQuestionImage(String? imageBase64) {
    if (imageBase64 == null) {
      return const SizedBox.shrink();
    }

    // Use a UniqueKey to prevent unnecessary rebuilds
    return Container(
      key: UniqueKey(),
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 250, minHeight: 100),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildStableImage(imageBase64),
      ),
    );
  }

  // Separate method for image loading to isolate rebuilds
  Widget _buildStableImage(String imageBase64) {
    try {
      String base64String = imageBase64;
      if (imageBase64.contains('base64,')) {
        base64String = imageBase64.split('base64,').last;
      }

      // Remove any whitespace
      base64String = base64String.replaceAll(RegExp(r'\s'), '');

      // Ensure proper padding
      while (base64String.length % 4 != 0) {
        base64String += '=';
      }

      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.contain,
        width: double.infinity,
        height: 250,
        errorBuilder: (context, error, stackTrace) {
          print("❌ Image error: $error");
          return Container(
            height: 150,
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                "⚠️ Image could not be loaded",
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print("❌ Error loading image: $e");
      return Container(
        height: 150,
        color: Colors.red.withAlpha(26),
        child: const Center(
          child: Text(
            "Error loading image",
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  // Build text with proper symbol display
  Widget _buildMathText(String text, {TextStyle? style}) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Text(
      text,
      style:
          style ?? const TextStyle(fontSize: 18, color: AppColors.darkPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);
    final notifier = ref.read(quizProvider.notifier);

    // DIRECT TIMER CHECK - Force navigation when time reaches zero
    if (state.isQuizStarted && state.seconds <= 0) {
      print("⏰ DIRECT CHECK: Timer is zero - forcing navigation");

      // Use WidgetsBinding to ensure we're not in the middle of a build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          // Submit the quiz
          await ref.read(quizProvider.notifier).submitQuiz();

          print("✅ submitQuiz() completed");

          // Clear all data
          ref.read(quizProvider.notifier).clearAllStudentData();

          // Navigate to login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const StudentView()),
            (route) => false,
          );

          // Show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Time expired! Exam Submitted"),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

      // Return a loading indicator while navigating
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Time expired. Logging out..."),
            ],
          ),
        ),
      );
    }

    if (!state.isQuizStarted &&
        state.questions.isEmpty &&
        state.studentMatric == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading exam...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final currentQ = state.questions[state.currentQuestionIndex];
    final String type = currentQ['type'] ?? 'OBJ';
    final imageBase64 = state.questionImages[state.currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left sidebar with student details and question navigator
          Container(
            width: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.0,
                colors: [
                  AppColors.darkSecondary,
                  AppColors.darkPrimary,
                  AppColors.darkAccent,
                ],
                stops: const [0.2, 0.5, 0.8],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student profile section
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimary.withAlpha(60),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 24,
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.studentName ?? 'Student Name',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.surface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.studentMatric ?? 'MATRIC',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.surface.withAlpha(204),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 1,
                      color: AppColors.surface.withAlpha(51),
                    ),

                    const SizedBox(height: 16),

                    // Question Navigator
                    Expanded(child: _buildQuestionNavigator(state)),
                  ],
                ),
              ),
            ),
          ),

          // Right content area
          Expanded(
            child: Column(
              children: [
                _buildHeader(state, notifier),
                LinearProgressIndicator(
                  value:
                      (state.currentQuestionIndex + 1) / state.questions.length,
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question image (if any)
                        _buildQuestionImage(imageBase64),

                        // Question counter with styling
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Question ${state.currentQuestionIndex + 1} of ${state.questions.length}",
                            style: TextStyle(
                              color: AppColors.darkPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Question text with math rendering
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withAlpha(26),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildMathText(
                            currentQ['text'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Answer area
                        _buildAnswerArea(type, currentQ, state, notifier),
                      ],
                    ),
                  ),
                ),
                _buildNavigationFooter(state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(QuizState state, dynamic notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            state.courseTitle,
            style: const TextStyle(
              color: AppColors.darkPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: state.isUrgent ? AppColors.error : AppColors.darkPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                notifier.timerText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea(
    String type,
    Map q,
    QuizState state,
    dynamic notifier,
  ) {
    if (type == 'TYPED') {
      _typedController.text =
          state.selectedAnswers[state.currentQuestionIndex] ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _typedController,
            onChanged: (val) =>
                notifier.selectAnswer(state.currentQuestionIndex, val),
            decoration: InputDecoration(
              labelText: "Type your answer",
              hintText: "Enter your answer here...",
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Your answer will be automatically compared with the correct answer (case-insensitive).",
                    style: TextStyle(fontSize: 12, color: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (type == 'THEORY') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: const Text(
          "✍️ This is a Theory Question. Please write your detailed answer in the provided physical answer booklet.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    } else {
      // OBJ questions
      return Column(
        children: ['A', 'B', 'C', 'D'].map((letter) {
          final optText = q['option$letter'] ?? '';
          if (optText.isEmpty) return const SizedBox.shrink();

          final isSelected =
              state.selectedAnswers[state.currentQuestionIndex] == letter;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.darkPrimary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: RadioListTile<String>(
              title: _buildMathText(
                optText,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              value: letter,
              groupValue: state.selectedAnswers[state.currentQuestionIndex],
              onChanged: (val) =>
                  notifier.selectAnswer(state.currentQuestionIndex, val!),
              activeColor: AppColors.darkPrimary,
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildNavigationFooter(QuizState state, dynamic notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(border: Border.all(width: 0.1)),
      child: Row(
        children: [
          if (state.currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: AppColors.darkPrimary, width: 1.5),
                ),
                onPressed: notifier.prevQuestion,
                child: Text(
                  "PREVIOUS",
                  style: TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),

          const SizedBox(width: 16),

          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (state.currentQuestionIndex == state.questions.length - 1)
                    ? AppColors.pass
                    : AppColors.darkPrimary,
                minimumSize: const Size(double.infinity, 55),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () {
                      _pingProgress(
                        state.currentQuestionIndex,
                        state.questions.length,
                      );
                      if (state.currentQuestionIndex <
                          state.questions.length - 1) {
                        notifier.nextQuestion();
                      } else {
                        _handleFinish(context, ref);
                      }
                    },
              child: Text(
                (state.currentQuestionIndex == state.questions.length - 1)
                    ? "SUBMIT EXAM"
                    : "NEXT QUESTION",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
