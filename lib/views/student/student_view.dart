import 'package:cbtapp/providers/quiz_provider.dart';
import 'package:cbtapp/views/student/student_quiz_view.dart';
import 'package:cbtapp/views/student/widgets/login_screen.dart';
import 'package:cbtapp/views/student/widgets/waiting_room.dart';
import 'package:cbtapp/utils/csv_helper.dart';
import 'package:cbtapp/widgets/server_connection_widget.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class StudentView extends ConsumerStatefulWidget {
  const StudentView({super.key});

  @override
  ConsumerState<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends ConsumerState<StudentView> {
  final _matricController = TextEditingController();
  final _surnameController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _studentData;

  @override
  void dispose() {
    _matricController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _attemptLogin() async {
    final matric = _matricController.text.trim().toUpperCase();
    final surname = _surnameController.text.trim().toUpperCase();

    if (matric.isEmpty || surname.isEmpty) {
      _showError("Please enter your Matric Number and Surname.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final serverIp = Uri.base.host.isEmpty ? "localhost" : Uri.base.host;
      final response = await http
          .post(
            Uri.parse('http://$serverIp:8080/api/login'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              'matric': matric,
              'surname': surname,
              // No subject field - server determines from enrollment
            }),
          )
          .timeout(const Duration(seconds: 5));

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['status'] == 'success') {
        final config = result['config'];

        ref
            .read(quizProvider.notifier)
            .setStudentInfo(
              matric: matric,
              fullName:
                  "${surname.toUpperCase()} ${result['firstName'].toUpperCase()}",
            );

        setState(() {
          _studentData = {
            'matric': matric,
            'name': "$surname ${result['firstName']}",
            'exam': config['course'],
            'durationRaw': int.parse(config['duration']),
            'durationDisplay': "${config['duration']} Minutes",
            'limit': config['totalToAnswer'],
            'subjectCode': config['subjectCode'],
          };
        });
      } else {
        _showError(result['message'] ?? "Invalid Credentials.");
      }
    } catch (e) {
      _showError(
        "Connection error. Ensure you are connected to the Exam Wi-Fi.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchQuestionsAndStart() async {
    setState(() => _isLoading = true);
    try {
      final serverIp = Uri.base.host.isEmpty ? "localhost" : Uri.base.host;

      // Must have subject code - no default fallback
      final subjectCode = _studentData!['subjectCode'];
      final url = 'http://$serverIp:8080/questions.csv?subject=$subjectCode';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final csvString = response.body;
        final rows = CsvHelper.parseCsv(csvString);

        List<Map<String, dynamic>> allQuestions = rows
            .skip(1) // Skip header
            .where((r) => r.length >= 7)
            .map((r) {
              // Check if there's an image column (index 7)
              String? imageBase64;
              if (r.length > 7 && r[7].toString().isNotEmpty) {
                imageBase64 = r[7].toString();
                print(
                  "📸 Found image for question: ${r[1].toString().substring(0, min(30, r[1].toString().length))}...",
                );
              }

              return {
                'type': r[0].toString(),
                'text': r[1].toString(),
                'optionA': r.length > 2 ? r[2].toString() : '',
                'optionB': r.length > 3 ? r[3].toString() : '',
                'optionC': r.length > 4 ? r[4].toString() : '',
                'optionD': r.length > 5 ? r[5].toString() : '',
                'answer': r.length > 6 ? r[6].toString() : '',
                'imageBase64': imageBase64, // Include image data
              };
            })
            .toList();

        print("📚 Loaded ${allQuestions.length} questions");

        // Count questions with images
        int imageCount = allQuestions
            .where((q) => q['imageBase64'] != null)
            .length;
        print("📸 Questions with images: $imageCount/${allQuestions.length}");

        allQuestions.shuffle();
        final selectedQuestions = allQuestions
            .take(_studentData!['limit'])
            .toList();

        ref
            .read(quizProvider.notifier)
            .startQuiz(
              questions: selectedQuestions,
              course: _studentData!['exam'],
              durationMinutes: _studentData!['durationRaw'],
              sessionCode: _studentData!['subjectCode'],
            );
      } else {
        _showError("Question bank not found for this session.");
      }
    } catch (e) {
      _showError("Error downloading questions: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final serverHost = Uri.base.host.isEmpty ? "localhost" : Uri.base.host;

    return ServerConnectionWidget(
      serverHost: serverHost,
      serverPort: 8080,
      checkInterval: const Duration(seconds: 10),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildBody(quizState),
      ),
    );
  }

  Widget _buildBody(QuizState quizState) {
    if (_studentData == null) {
      return LoginScreen(
        matricController: _matricController,
        surnameController: _surnameController,
        onLoginPressed: _attemptLogin,
        isLoading: _isLoading,
      );
    }

    if (!quizState.isQuizStarted) {
      return WaitingRoom(
        studentData: _studentData!,
        onLogout: () => setState(() => _studentData = null),
        onStartExam: _fetchQuestionsAndStart,
        isLoading: _isLoading,
      );
    }

    return const StudentQuizView();
  }
}
