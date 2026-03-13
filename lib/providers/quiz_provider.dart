import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class QuizState {
  final List<Map<String, dynamic>> questions;
  final String courseTitle;
  final String? sessionCode;
  final int seconds;
  final bool isUrgent;
  final int currentQuestionIndex;
  final Map<int, dynamic> selectedAnswers;
  final bool isQuizStarted;
  final bool isSubmitted;
  final String? studentMatric;
  final String? studentName;
  final Map<int, String?> questionImages;

  QuizState({
    this.questions = const [],
    this.courseTitle = "Loading Exam...",
    this.sessionCode,
    this.seconds = 3600,
    this.isUrgent = false,
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.isQuizStarted = false,
    this.isSubmitted = false,
    this.studentMatric,
    this.studentName,
    this.questionImages = const {},
  });

  QuizState copyWith({
    List<Map<String, dynamic>>? questions,
    String? courseTitle,
    String? sessionCode,
    int? seconds,
    bool? isUrgent,
    int? currentQuestionIndex,
    Map<int, dynamic>? selectedAnswers,
    bool? isQuizStarted,
    bool? isSubmitted,
    String? studentMatric,
    String? studentName,
    Map<int, String?>? questionImages,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      courseTitle: courseTitle ?? this.courseTitle,
      sessionCode: sessionCode ?? this.sessionCode,
      seconds: seconds ?? this.seconds,
      isUrgent: isUrgent ?? this.isUrgent,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isQuizStarted: isQuizStarted ?? this.isQuizStarted,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      studentMatric: studentMatric ?? this.studentMatric,
      studentName: studentName ?? this.studentName,
      questionImages: questionImages ?? this.questionImages,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(QuizState());
  Timer? _timer;
  Timer? _autoSaveTimer;
  int _typedCorrectCount = 0;

  void setStudentInfo({required String matric, required String fullName}) {
    print("👤 Setting student info: $matric - $fullName");
    state = state.copyWith(studentMatric: matric, studentName: fullName);
  }

  void startQuiz({
    required List<Map<String, dynamic>> questions,
    required String course,
    required int durationMinutes,
    required String sessionCode,
  }) {
    print("🎯 Starting quiz for session: $sessionCode");
    print("   Course: $course");
    print("   Duration: $durationMinutes minutes");
    print("   Questions: ${questions.length}");

    // Count questions with images
    int imageCount = questions.where((q) => q['imageBase64'] != null).length;
    print("📸 Questions with images: $imageCount/${questions.length}");

    // Ensure any existing state is completely cleared
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _timer = null;
    _autoSaveTimer = null;
    _typedCorrectCount = 0;

    // Extract images from questions
    final Map<int, String?> images = {};
    for (int i = 0; i < questions.length; i++) {
      images[i] = questions[i]['imageBase64'];
      if (questions[i]['imageBase64'] != null) {
        print(
          "📸 Stored image for question $i, length: ${questions[i]['imageBase64'].length}",
        );
      }
    }

    state = state.copyWith(
      questions: questions,
      courseTitle: course,
      sessionCode: sessionCode,
      seconds: durationMinutes * 60,
      isQuizStarted: true,
      currentQuestionIndex: 0,
      selectedAnswers: {},
      questionImages: images, // This is critical!
    );

    _startTimer();
    _startAutoSave();

    print(
      "✅ Quiz started with fresh state, ${images.length} total questions, ${images.values.where((v) => v != null).length} with images",
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.seconds > 0) {
        state = state.copyWith(
          seconds: state.seconds - 1,
          isUrgent: state.seconds <= 60,
        );
      } else {
        print("⏰ Timer reached zero");
        _timer?.cancel();
        _autoSaveTimer?.cancel();

        // Set a flag to indicate time's up - this will trigger the listener
        state = state.copyWith(seconds: 0);

        t.cancel();
      }
    });
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _saveProgress();
    });
  }

  // Add this new method to QuizNotifier
  void clearAllStudentData() {
    print("🧹 Completely clearing all student data");

    // Cancel all timers
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _timer = null;
    _autoSaveTimer = null;

    // Reset all counters
    _typedCorrectCount = 0;

    // Create brand new state - this is the nuclear option
    state = QuizState();

    // Force a rebuild by copying (though not necessary after setting to new instance)
    print("✅ All student data cleared");
  }

  Future<void> _saveProgress() async {
    // Add this check at the beginning
    if (state.studentMatric == null ||
        state.studentMatric!.isEmpty ||
        state.questions.isEmpty) {
      print("⏭️ Skipping auto-save - no active exam");
      return;
    }

    try {
      final progress = {
        'questions': state.questions,
        'selectedAnswers': state.selectedAnswers.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
        'currentIndex': state.currentQuestionIndex,
        'seconds': state.seconds,
        'studentMatric': state.studentMatric,
        'studentName': state.studentName,
        'courseTitle': state.courseTitle,
        'sessionCode': state.sessionCode,
      };

      final file = File('exam_progress_${state.studentMatric}.json');
      await file.writeAsString(jsonEncode(progress));
      print("💾 Auto-saved progress for ${state.studentMatric}");
    } catch (e) {
      print("❌ Auto-save failed: $e");
    }
  }

  Future<bool> resumeProgress(String matric) async {
    final file = File('exam_progress_$matric.json');
    if (!await file.exists()) return false;

    try {
      final data = jsonDecode(await file.readAsString());

      // Convert string keys back to integers
      final selectedAnswers = <int, dynamic>{};
      if (data['selectedAnswers'] != null) {
        (data['selectedAnswers'] as Map).forEach((key, value) {
          selectedAnswers[int.parse(key)] = value;
        });
      }

      state = state.copyWith(
        questions: List<Map<String, dynamic>>.from(data['questions']),
        selectedAnswers: selectedAnswers,
        currentQuestionIndex: data['currentIndex'],
        seconds: data['seconds'],
        studentMatric: data['studentMatric'],
        studentName: data['studentName'],
        courseTitle: data['courseTitle'],
        sessionCode: data['sessionCode'],
        isQuizStarted: true,
      );

      _startTimer();
      _startAutoSave();
      print("✅ Resumed exam for $matric");
      return true;
    } catch (e) {
      print("❌ Resume failed: $e");
      return false;
    }
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentQuestionIndex: index);
    }
  }

  bool isQuestionAnswered(int index) {
    return state.selectedAnswers.containsKey(index) &&
        state.selectedAnswers[index] != null &&
        state.selectedAnswers[index].toString().isNotEmpty;
  }

  String getQuestionStatus(int index) {
    if (index == state.currentQuestionIndex) return 'current';
    if (isQuestionAnswered(index)) return 'answered';
    return 'unanswered';
  }

  Future<void> submitQuiz() async {
    print("📤 submitQuiz() started");

    // Cancel timers FIRST
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _timer = null;
    _autoSaveTimer = null;

    if (state.studentMatric == null || state.studentMatric!.isEmpty) {
      print("❌ No student matric found, cannot submit");
      state = QuizState();
      return;
    }

    // Store matric for file deletion
    final String matric = state.studentMatric!;
    final String studentName = state.studentName ?? "Student";

    int correctCount = 0;
    int totalObj = 0;
    int totalTyped = 0;
    int totalTheory = 0;
    int typedCorrectCount = 0;

    for (int i = 0; i < state.questions.length; i++) {
      final question = state.questions[i];
      final questionType = question['type'] ?? 'OBJ';
      final studentAnswer = state.selectedAnswers[i]?.toString().trim() ?? '';

      if (questionType == 'OBJ') {
        totalObj++;
        final correctAnswer = question['answer']
            ?.toString()
            .trim()
            .toUpperCase();
        if (studentAnswer.isNotEmpty &&
            studentAnswer.toUpperCase() == correctAnswer) {
          correctCount++;
        }
      } else if (questionType == 'TYPED') {
        totalTyped++;
        final correctAnswer = question['answer']
            ?.toString()
            .trim()
            .toLowerCase();
        if (studentAnswer.isNotEmpty &&
            studentAnswer.toLowerCase().trim() == correctAnswer) {
          correctCount++;
          typedCorrectCount++;
        }
      } else if (questionType == 'THEORY') {
        totalTheory++;
      }
    }

    double finalScore = (totalObj + totalTyped) > 0
        ? (correctCount / (totalObj + totalTyped)) * 100
        : 0;

    String surname = state.studentName?.split(' ').first ?? "Unknown";
    String firstname = state.studentName?.contains(' ') == true
        ? state.studentName!.split(' ').sublist(1).join(' ')
        : "Student";

    String subjectCode =
        state.sessionCode ??
        state.courseTitle.replaceAll(' ', '_').toUpperCase();

    print("📤 Submitting exam for $matric");
    print("   Subject: $subjectCode");
    print("   OBJ: $correctCount/$totalObj");
    print("   TYPED: $typedCorrectCount/$totalTyped");
    print("   THEORY: $totalTheory");
    print("   Score: ${finalScore.toStringAsFixed(1)}%");

    try {
      final response = await http
          .post(
            Uri.parse('http://${Uri.base.host}:8080/api/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'matric': matric,
              'surname': surname,
              'firstname': firstname,
              'subject': subjectCode,
              'obj_correct': correctCount,
              'total_obj': totalObj,
              'typed_correct': typedCorrectCount,
              'total_typed': totalTyped,
              'theory_answered': totalTheory > 0 ? 1 : 0,
              'total_theory': totalTheory,
              'score': finalScore.toStringAsFixed(1),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print("✅ Exam successfully uploaded to server.");
      } else {
        print("❌ Submission failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Submission failed: $e");
    } finally {
      // Delete saved progress file
      try {
        final file = File('exam_progress_$matric.json');
        if (await file.exists()) {
          await file.delete();
          print("🗑️ Deleted saved progress file for $matric");
        }
      } catch (e) {
        print("❌ Error deleting progress file: $e");
      }

      // Clear all data using the new method
      clearAllStudentData();
    }
  }

  // Future<void> _autoSubmitOnTimeout() async {
  //   print("⏰ Timer expired - auto-submitting exam...");

  //   if (state.studentMatric == null || state.studentMatric!.isEmpty) {
  //     print("❌ No student matric found, cannot auto-submit");
  //     clearAllStudentData();
  //     return;
  //   }

  //   final String matric = state.studentMatric!;

  //   // ... calculation code (same as before) ...

  //   try {
  //     final response = await http
  //         .post(
  //           Uri.parse('http://${Uri.base.host}:8080/api/submit'),
  //           headers: {'Content-Type': 'application/json'},
  //           body: jsonEncode({
  //             // ... same body as before ...
  //           }),
  //         )
  //         .timeout(const Duration(seconds: 10));

  //     if (response.statusCode == 200) {
  //       print("✅ Exam auto-submitted due to timeout.");
  //     } else {
  //       print("❌ Auto-submission failed with status: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("❌ Auto-submission failed: $e");
  //   } finally {
  //     // Delete saved progress
  //     final file = File('exam_progress_$matric.json');
  //     if (await file.exists()) await file.delete();

  //     _autoSaveTimer?.cancel();
  //     _timer?.cancel();

  //     // Clear all data using the new method
  //     clearAllStudentData();
  //   }
  // }

  void selectAnswer(int qIndex, dynamic answer) {
    final newAnswers = Map<int, dynamic>.from(state.selectedAnswers);
    newAnswers[qIndex] = answer;
    state = state.copyWith(selectedAnswers: newAnswers);
  }

  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  void prevQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
    }
  }

  String get timerText {
    final m = (state.seconds ~/ 60).toString().padLeft(2, '0');
    final s = (state.seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(),
);
