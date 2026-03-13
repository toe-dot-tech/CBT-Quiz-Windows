import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:cbtapp/utils/csv_helper.dart';
import 'package:path/path.dart' as path;

// Student model
class Student {
  final String matric;
  final String surname;
  final String firstname;
  final String? studentClass;
  Set<String> enrolledSubjects; // Subjects the student can take

  Student({
    required this.matric,
    required this.surname,
    required this.firstname,
    this.studentClass,
    this.enrolledSubjects = const {},
  });

  Map<String, dynamic> toJson() => {
    'matric': matric,
    'surname': surname,
    'firstname': firstname,
    'class': studentClass,
    'subjects': enrolledSubjects.toList(),
  };
}

// Subject model
class Subject {
  final String code;
  final String title;
  final int duration;
  final int questionLimit;
  final String questionBankFile;
  final List<String> enrolledStudents;
  final Set<String> completedStudents;
  int questionCount;

  Subject({
    required this.code,
    required this.title,
    required this.duration,
    required this.questionLimit,
    required this.questionBankFile,
    this.enrolledStudents = const [],
    this.completedStudents = const {},
    this.questionCount = 0,
  });

  Subject copyWith({
    String? title,
    int? duration,
    int? questionLimit,
    List<String>? enrolledStudents,
    Set<String>? completedStudents,
    int? questionCount,
  }) {
    return Subject(
      code: code,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      questionLimit: questionLimit ?? this.questionLimit,
      questionBankFile: questionBankFile,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      completedStudents: completedStudents ?? this.completedStudents,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}

// Exam session
class ExamSession {
  final Subject subject;
  final DateTime startTime;
  final Map<String, DateTime> activeStudents;
  final Set<String> forceLoggedOutStudents;

  ExamSession({
    required this.subject,
    required this.startTime,
    this.activeStudents = const {},
    this.forceLoggedOutStudents = const {},
  });

  ExamSession copyWith({
    Subject? subject,
    DateTime? startTime,
    Map<String, DateTime>? activeStudents,
    Set<String>? forceLoggedOutStudents,
  }) {
    return ExamSession(
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      activeStudents: activeStudents ?? this.activeStudents,
      forceLoggedOutStudents:
          forceLoggedOutStudents ?? this.forceLoggedOutStudents,
    );
  }
}

// Track student progress per subject
class StudentProgress {
  final String matric;
  final String subjectCode;
  final DateTime startTime;
  DateTime? endTime;
  final Map<int, dynamic> answers;
  int currentQuestionIndex;
  bool isCompleted;
  bool isSubmitted;
  bool isForceLoggedOut;

  StudentProgress({
    required this.matric,
    required this.subjectCode,
    required this.startTime,
    this.endTime,
    this.answers = const {},
    this.currentQuestionIndex = 0,
    this.isCompleted = false,
    this.isSubmitted = false,
    this.isForceLoggedOut = false,
  });
}

class QuizServer {
  static final QuizServer _instance = QuizServer._internal();
  factory QuizServer() => _instance;
  QuizServer._internal();

  HttpServer? _serverInstance;

  // Static property for connected clients
  static List<String> connectedClients = [];

  // Core data structures
  static final Map<String, Subject> _subjects = {}; // subjectCode -> Subject
  static final Map<String, Student> _students = {}; // matric -> Student
  static final Map<String, ExamSession> _activeSessions =
      {}; // subjectCode -> ExamSession
  static final Map<String, Map<String, StudentProgress>> _studentProgress =
      {}; // matric -> (subjectCode -> progress)

  final _updateController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get studentStream => _updateController.stream;

  final _subjectUpdateController = StreamController<void>.broadcast();
  Stream<void> get subjectUpdateStream => _subjectUpdateController.stream;

  bool get isRunning => _serverInstance != null;

  // Initialize from CSV (students only)
  Future<void> initializeFromCsv() async {
    final file = File('registered_students.csv');
    if (await file.exists()) {
      final csvString = await file.readAsString();
      final rows = CsvHelper.parseCsv(
        csvString,
      ).map((row) => row as List<dynamic>).toList();

      for (var row in rows.skip(1)) {
        if (row.length >= 3) {
          final matric = row[0].toString().trim().toUpperCase();
          final surname = row[1].toString().trim().toUpperCase();
          final firstname = row[2].toString().trim();
          final studentClass = row.length > 3 ? row[3].toString() : null;

          _students[matric] = Student(
            matric: matric,
            surname: surname,
            firstname: firstname,
            studentClass: studentClass,
          );
        }
      }
      print("📚 Loaded ${_students.length} students from CSV");
    }
  }

  // Get available subjects
  List<String> getAvailableSubjects() {
    return _subjects.keys.toList();
  }

  // Get student's enrolled subjects
  List<String> getStudentEnrolledSubjects(String matric) {
    final student = _students[matric];
    if (student == null) {
      print("❌ Student $matric not found when getting enrolled subjects");
      return [];
    }

    print(
      "📚 Student $matric enrolled subjects: ${student.enrolledSubjects.toList()}",
    );
    return student.enrolledSubjects.toList();
  }

  // Get student's enrolled subjects with full details
  List<Map<String, dynamic>> getStudentEnrolledSubjectsWithDetails(
    String matric,
  ) {
    final student = _students[matric];
    if (student == null) return [];

    final List<Map<String, dynamic>> result = [];
    for (var subjectCode in student.enrolledSubjects) {
      final subject = _subjects[subjectCode];
      if (subject != null) {
        result.add({
          'code': subject.code,
          'title': subject.title,
          'duration': subject.duration,
          'questionLimit': subject.questionLimit,
          'questionCount': subject.questionCount,
        });
      }
    }
    return result;
  }

  // Create exam session for a subject
  void createExamSession({
    required String subjectCode,
    required String courseTitle,
    required int duration,
    required int questionLimit,
  }) {
    final questionBankFile = 'questions_${subjectCode.toLowerCase()}.csv';

    // Create subject
    _subjects[subjectCode] = Subject(
      code: subjectCode,
      title: courseTitle,
      duration: duration,
      questionLimit: questionLimit,
      questionBankFile: questionBankFile,
    );

    // Create question bank file if it doesn't exist
    final file = File(questionBankFile);
    if (!file.existsSync()) {
      file.writeAsStringSync("Type,Text,OptA,OptB,OptC,OptD,Answer\n");
    }

    // Create exam session
    _activeSessions[subjectCode] = ExamSession(
      subject: _subjects[subjectCode]!,
      startTime: DateTime.now(),
    );

    print("📚 Created exam session for $subjectCode");
    _subjectUpdateController.add(null);
  }

  // Edit exam session
  void editExamSession({
    required String subjectCode,
    required String courseTitle,
    required int duration,
    required int questionLimit,
  }) {
    if (_subjects.containsKey(subjectCode)) {
      final subject = _subjects[subjectCode]!;
      _subjects[subjectCode] = subject.copyWith(
        title: courseTitle,
        duration: duration,
        questionLimit: questionLimit,
      );

      if (_activeSessions.containsKey(subjectCode)) {
        final oldSession = _activeSessions[subjectCode]!;
        _activeSessions[subjectCode] = oldSession.copyWith(
          subject: _subjects[subjectCode]!,
        );
      }

      print("📝 Edited exam session for $subjectCode");
      _subjectUpdateController.add(null);
    }
  }

  // Update question count for a subject
  void updateQuestionCount(String subjectCode, int count) {
    if (_subjects.containsKey(subjectCode)) {
      final subject = _subjects[subjectCode]!;
      _subjects[subjectCode] = subject.copyWith(
        questionCount: subject.questionCount + count,
      );
      _subjectUpdateController.add(null);
    }
  }

  // Clear all sessions
  void clearAllSessions() {
    for (var subject in _subjects.values) {
      try {
        final file = File(subject.questionBankFile);
        if (file.existsSync()) {
          file.deleteSync();
          print("🗑️ Deleted question bank: ${subject.questionBankFile}");
        }
      } catch (e) {
        print("⚠️ Error deleting ${subject.questionBankFile}: $e");
      }
    }

    _subjects.clear();
    _activeSessions.clear();

    _students.forEach((matric, student) {
      student.enrolledSubjects.clear();
    });

    _subjectUpdateController.add(null);
    print("🧹 Cleared all exam sessions");
  }

  // Import students from CSV for a subject
  Future<Map<String, dynamic>> importStudentsFromCsv(
    File file,
    String subjectCode,
  ) async {
    int added = 0;
    int existing = 0;
    int failed = 0;
    List<String> newMatrics = [];

    try {
      final csvString = await file.readAsString();
      final rows = CsvHelper.parseCsv(
        csvString,
      ).map((row) => row as List<dynamic>).toList();

      for (var row in rows.skip(1)) {
        if (row.length >= 3) {
          try {
            final matric = row[0].toString().trim().toUpperCase();
            final surname = row[1].toString().trim().toUpperCase();
            final firstname = row[2].toString().trim();
            final studentClass = row.length > 3 ? row[3].toString() : null;

            if (!_students.containsKey(matric)) {
              _students[matric] = Student(
                matric: matric,
                surname: surname,
                firstname: firstname,
                studentClass: studentClass,
                enrolledSubjects: {subjectCode},
              );
              newMatrics.add(matric);
              added++;
            } else {
              final student = _students[matric]!;
              if (!student.enrolledSubjects.contains(subjectCode)) {
                student.enrolledSubjects.add(subjectCode);
                newMatrics.add(matric);
                added++;
              } else {
                existing++;
              }
            }
          } catch (e) {
            failed++;
          }
        }
      }

      if (_subjects.containsKey(subjectCode) && newMatrics.isNotEmpty) {
        final subject = _subjects[subjectCode]!;
        final updatedList = List<String>.from(subject.enrolledStudents)
          ..addAll(newMatrics);
        _subjects[subjectCode] = subject.copyWith(
          enrolledStudents: updatedList,
        );
        print(
          "✅ Updated subject $subjectCode enrolled list: now has ${updatedList.length} students",
        );
      }

      _subjectUpdateController.add(null);

      return {
        'added': added,
        'existing': existing,
        'failed': failed,
        'total': rows.length - 1,
      };
    } catch (e) {
      print("❌ Error importing students: $e");
      return {
        'added': 0,
        'existing': 0,
        'failed': 0,
        'total': 0,
        'error': e.toString(),
      };
    }
  }

  // Enroll student in subjects
  void enrollStudentInSubjects(String matric, List<String> subjectCodes) {
    if (!_students.containsKey(matric)) {
      print("❌ Student $matric not found in registry");
      return;
    }

    final student = _students[matric]!;
    print(
      "📚 Current enrolled subjects for $matric: ${student.enrolledSubjects}",
    );

    // Add subjects to student
    student.enrolledSubjects.addAll(subjectCodes);
    print(
      "📚 Updated enrolled subjects for $matric: ${student.enrolledSubjects}",
    );

    // Update each subject's enrolled students list
    for (var code in subjectCodes) {
      if (_subjects.containsKey(code)) {
        final subject = _subjects[code]!;

        // Check if student is already in the list to avoid duplicates
        if (!subject.enrolledStudents.contains(matric)) {
          final updatedList = List<String>.from(subject.enrolledStudents)
            ..add(matric);
          _subjects[code] = subject.copyWith(enrolledStudents: updatedList);
          print(
            "✅ Added $matric to subject $code enrolled list. Now has ${updatedList.length} students",
          );
        } else {
          print("ℹ️ Student $matric already in subject $code enrolled list");
        }
      } else {
        print("⚠️ Subject $code not found when enrolling student");
      }
    }

    // Force UI update
    _subjectUpdateController.add(null);
    print(
      "✅ Enrollment complete for $matric in subjects: ${subjectCodes.join(', ')}",
    );
  }

  // Check if student can take exam
  bool canTakeExam(String matric, String subjectCode) {
    print("🔍 Checking if $matric can take $subjectCode");

    if (!_students.containsKey(matric)) {
      print("❌ Student not found");
      return false;
    }

    if (!_subjects.containsKey(subjectCode)) {
      print("❌ Subject not found");
      return false;
    }

    final student = _students[matric]!;
    final subject = _subjects[subjectCode]!;

    if (!student.enrolledSubjects.contains(subjectCode)) {
      print("❌ Student not enrolled in $subjectCode");
      return false;
    }

    if (_studentProgress.containsKey(matric) &&
        _studentProgress[matric]!.containsKey(subjectCode)) {
      final progress = _studentProgress[matric]![subjectCode]!;
      if (progress.isCompleted || progress.isSubmitted) {
        print("❌ Student already completed $subjectCode");
        return false;
      }
    }

    if (subject.completedStudents.contains(matric)) {
      print("❌ Student already in completed list");
      return false;
    }

    print("✅ Student can take exam");
    return true;
  }

  // Check if student was force logged out
  bool isForceLoggedOut(String matric, String subjectCode) {
    if (_studentProgress.containsKey(matric) &&
        _studentProgress[matric]!.containsKey(subjectCode)) {
      return _studentProgress[matric]![subjectCode]!.isForceLoggedOut;
    }
    return false;
  }

  // Get the correct path for assets in release mode
  String getAssetPath() {
    final exeDir = path.dirname(Platform.resolvedExecutable);
    print('🔍 Executable directory: $exeDir');

    final possiblePaths = [
      path.join(Directory.current.path, 'assets', 'web'),
      path.join(exeDir, 'assets', 'web'),
      path.join(exeDir, 'data', 'flutter_assets', 'assets', 'web'),
      path.join(path.dirname(exeDir), 'assets', 'web'),
    ];

    for (var p in possiblePaths) {
      if (Directory(p).existsSync()) {
        print('✅ Found web assets at: $p');
        final indexPath = path.join(p, 'index.html');
        if (File(indexPath).existsSync()) {
          print('  ✅ index.html found');
          return p;
        } else {
          print('  ❌ index.html missing at: $indexPath');
        }
      }
    }

    print('❌ Could not find web assets in any location!');
    return '';
  }

  // Force logout a student
  void forceLogout(String matric) {
    connectedClients.removeWhere((s) => s.contains(matric));

    _studentProgress.forEach((matricKey, progressMap) {
      if (matricKey == matric) {
        progressMap.forEach((subjectCode, progress) {
          progress.isForceLoggedOut = true;
        });
      }
    });

    _updateController.add(connectedClients);
    print("👋 Force logged out student: $matric");
  }

  // Allow student retake for a specific subject
  void allowRetake(String matric, String subjectCode) {
    if (_studentProgress.containsKey(matric)) {
      _studentProgress[matric]!.remove(subjectCode);
    }

    if (_subjects.containsKey(subjectCode)) {
      final subject = _subjects[subjectCode]!;
      final updatedSet = Set<String>.from(subject.completedStudents)
        ..remove(matric);
      _subjects[subjectCode] = subject.copyWith(completedStudents: updatedSet);
    }

    print("🔄 Allowed retake for student: $matric in subject: $subjectCode");
    _subjectUpdateController.add(null);
  }

  // Get student's completed subjects
  List<String> getStudentCompletedSubjects(String matric) {
    final progressMap = _studentProgress[matric];
    if (progressMap == null) return [];

    return progressMap.entries
        .where((entry) => entry.value.isCompleted)
        .map((entry) => entry.key)
        .toList();
  }

  Future<String> start() async {
    if (_serverInstance != null) return "Already Running";

    final assetPath = getAssetPath();

    if (assetPath.isEmpty || !Directory(assetPath).existsSync()) {
      print('❌ Web assets directory not found!');
      return "ASSETS_NOT_FOUND";
    }

    print('📁 Serving web assets from: $assetPath');

    final indexPath = path.join(assetPath, 'index.html');
    if (!File(indexPath).existsSync()) {
      print('❌ index.html not found at: $indexPath');
      return "ASSETS_NOT_FOUND";
    }

    final router = Router();

    // Health check endpoint
    router.get('/api/health', (Request req) {
      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'timestamp': DateTime.now().toIso8601String(),
          'subjects': _subjects.length,
          'students': _students.length,
          'activeClients': connectedClients.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // API Routes
    router.post('/api/login', (Request req) async {
      try {
        final data = jsonDecode(await req.readAsString());
        final String matric = data['matric'].toString().trim().toUpperCase();
        final String surname = data['surname'].toString().trim().toUpperCase();

        print("🔐 Login - Matric: $matric");

        final student = _students[matric];
        if (student == null || student.surname != surname) {
          return Response.forbidden(
            jsonEncode({'status': 'error', 'message': 'Invalid credentials'}),
          );
        }

        // Get all subjects the student is enrolled in
        final enrolledSubjects = student.enrolledSubjects.toList();

        if (enrolledSubjects.isEmpty) {
          return Response.forbidden(
            jsonEncode({
              'status': 'error',
              'message':
                  'You are not enrolled in any exam session. Please contact your administrator.',
            }),
          );
        }

        // For now, take the first enrolled subject
        final subjectCode = enrolledSubjects.first;
        final subject = _subjects[subjectCode];

        if (subject == null) {
          return Response.forbidden(
            jsonEncode({
              'status': 'error',
              'message':
                  'Exam session not found. Please contact your administrator.',
            }),
          );
        }

        // Check if already completed
        if (subject.completedStudents.contains(matric)) {
          return Response.forbidden(
            jsonEncode({
              'status': 'error',
              'message': 'You have already completed this exam.',
            }),
          );
        }

        // Check if force logged out
        if (isForceLoggedOut(matric, subjectCode)) {
          return Response.forbidden(
            jsonEncode({
              'status': 'error',
              'message': 'You have been logged out by the administrator.',
            }),
          );
        }

        // Get available question count
        final availablePool = await _getAvailableQuestionCount(subjectCode);

        // Track active session
        final displayName =
            "${student.firstname} ${student.surname} ($matric) - ${subject.code}";
        if (!connectedClients.contains(displayName)) {
          connectedClients.add(displayName);
          _updateController.add(connectedClients);
        }

        // Initialize progress tracking
        if (!_studentProgress.containsKey(matric)) {
          _studentProgress[matric] = {};
        }
        _studentProgress[matric]![subject.code] = StudentProgress(
          matric: matric,
          subjectCode: subject.code,
          startTime: DateTime.now(),
        );

        return Response.ok(
          jsonEncode({
            'status': 'success',
            'firstName': student.firstname,
            'surname': student.surname,
            'config': {
              'course': subject.title,
              'duration': subject.duration.toString(),
              'totalToAnswer': subject.questionLimit > availablePool
                  ? availablePool
                  : subject.questionLimit,
              'subjectCode': subject.code,
            },
          }),
        );
      } catch (e) {
        print("❌ Login error: $e");
        return Response.internalServerError(body: e.toString());
      }
    });

    router.post('/api/progress', (Request req) async {
      final data = jsonDecode(await req.readAsString());
      final String matric = data['matric'];
      final String progress = data['progress'];
      final String subjectCode = data['subjectCode'] ?? '';

      if (isForceLoggedOut(matric, subjectCode)) {
        return Response.forbidden(
          jsonEncode({
            'status': 'error',
            'message': 'You have been logged out by the administrator',
          }),
        );
      }

      for (int i = 0; i < connectedClients.length; i++) {
        if (connectedClients[i].contains(matric)) {
          connectedClients[i] = "$matric - $progress";
          break;
        }
      }
      _updateController.add(connectedClients);
      return Response.ok(jsonEncode({'status': 'updated'}));
    });

    router.get('/questions.csv', (Request req) async {
      final subjectCode = req.url.queryParameters['subject'] ?? '';

      if (!_subjects.containsKey(subjectCode)) {
        return Response.notFound(
          'Question bank not found for subject: $subjectCode',
        );
      }

      final questionBankFile = _subjects[subjectCode]!.questionBankFile;
      final file = File(questionBankFile);

      if (await file.exists()) {
        final contents = await file.readAsString();
        return Response.ok(contents, headers: {'content-type': 'text/csv'});
      }

      return Response.notFound('Question bank not found');
    });

    router.post('/api/submit', (Request req) async {
      final data = jsonDecode(await req.readAsString());
      await _saveLocally(data);

      final String matric = data['matric'];
      final String subjectCode = data['subject'] ?? '';

      if (!_subjects.containsKey(subjectCode)) {
        return Response.badRequest(body: 'Invalid subject');
      }

      if (isForceLoggedOut(matric, subjectCode)) {
        return Response.forbidden(
          jsonEncode({
            'status': 'error',
            'message': 'Cannot submit - you were logged out',
          }),
        );
      }

      // Mark as completed in StudentProgress
      final studentProgressMap = _studentProgress[matric];
      if (studentProgressMap != null &&
          studentProgressMap.containsKey(subjectCode)) {
        final progress = studentProgressMap[subjectCode]!;
        progress.isCompleted = true;
        progress.endTime = DateTime.now();
        progress.isSubmitted = true;
      }

      // Mark as completed in subject
      final subject = _subjects[subjectCode]!;
      final updatedSet = Set<String>.from(subject.completedStudents)
        ..add(matric);
      _subjects[subjectCode] = subject.copyWith(completedStudents: updatedSet);

      // Update live log
      connectedClients.removeWhere((s) => s.contains(matric));
      connectedClients.add("$matric - FINISHED ✅ ($subjectCode)");
      _updateController.add(connectedClients);

      _subjectUpdateController.add(null);

      return Response.ok(jsonEncode({'status': 'saved'}));
    });

    // Admin endpoint to force logout
    router.post('/api/admin/force-logout', (Request req) async {
      final data = jsonDecode(await req.readAsString());
      final String matric = data['matric'];
      forceLogout(matric);
      return Response.ok(jsonEncode({'status': 'success'}));
    });

    // Admin endpoint to allow retake
    router.post('/api/admin/allow-retake', (Request req) async {
      final data = jsonDecode(await req.readAsString());
      final String matric = data['matric'];
      final String subjectCode = data['subjectCode'];
      allowRetake(matric, subjectCode);
      return Response.ok(jsonEncode({'status': 'success'}));
    });

    // Admin endpoint to clear all sessions
    router.post('/api/admin/clear-sessions', (Request req) async {
      clearAllSessions();
      return Response.ok(jsonEncode({'status': 'success'}));
    });

    // Serve static files
    final staticHandler = createStaticHandler(
      assetPath,
      defaultDocument: 'index.html',
    );

    router.mount('/', staticHandler);

    try {
      _serverInstance = await io.serve(
        router.call,
        InternetAddress.anyIPv4,
        8080,
      );

      final ip = await _getNetworkIp();
      print('✅ Server started successfully!');
      print('🌐 Local URL: http://localhost:8080');
      print('🌐 Network URL: http://$ip:8080');
      print('📁 Serving from: $assetPath');

      return ip;
    } catch (e) {
      print('❌ Failed to start server: $e');
      return "SERVER_ERROR";
    }
  }

  Future<int> _getAvailableQuestionCount(String subjectCode) async {
    if (!_subjects.containsKey(subjectCode)) return 0;

    final subject = _subjects[subjectCode]!;
    final file = File(subject.questionBankFile);

    if (!await file.exists()) return 0;

    final csvString = await file.readAsString();
    final list = CsvHelper.parseCsv(
      csvString,
    ).map((row) => row as List<dynamic>).toList();
    return list.length > 1 ? list.length - 1 : 0;
  }

  Future<void> _saveLocally(Map<String, dynamic> data) async {
    final file = File('quiz_results.csv');
    if (!await file.exists()) {
      await file.writeAsString(
        "Timestamp,Matric,Surname,Firstname,Subject,Obj Correct,Total Obj,Typed Correct,Total Typed,Theory Answered,Total Theory,Score(%)\n",
      );
    }

    final row = [
      DateTime.now().toIso8601String(),
      data['matric'],
      data['surname'],
      data['firstname'] ?? 'N/A',
      data['subject'] ?? 'UNKNOWN',
      data['obj_correct'].toString(),
      data['total_obj'].toString(),
      data['typed_correct'].toString(),
      data['total_typed'].toString(),
      data['theory_answered'].toString(),
      data['total_theory'].toString(),
      data['score'],
    ];

    String csvRow = "${CsvHelper.listToCsv([row])}\n";
    await file.writeAsString(csvRow, mode: FileMode.append, flush: true);

    print("✅ DATA SAVED: ${data['matric']} - ${data['subject']}");
  }

  Future<String> _getNetworkIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (e) {
      print('Error getting network IP: $e');
    }
    return "localhost";
  }

  Future<void> stop() async {
    await _serverInstance?.close(force: true);
    _serverInstance = null;
    connectedClients.clear();
    _updateController.add(connectedClients);
  }

  void clearStudentList() {
    connectedClients.clear();
    _updateController.add(connectedClients);
  }

  // Getters
  Map<String, Subject> getSubjects() => _subjects;
  Map<String, Student> getStudents() => _students;

  Stream<void> getSubjectUpdateStream() => _subjectUpdateController.stream;

  // Remove a single exam session
  void removeExamSession(String subjectCode) {
    if (!_subjects.containsKey(subjectCode)) return;

    final subject = _subjects[subjectCode]!;

    try {
      final file = File(subject.questionBankFile);
      if (file.existsSync()) {
        file.deleteSync();
        print("🗑️ Deleted question bank: ${subject.questionBankFile}");
      }
    } catch (e) {
      print("⚠️ Error deleting ${subject.questionBankFile}: $e");
    }

    _subjects.remove(subjectCode);
    _activeSessions.remove(subjectCode);

    _students.forEach((matric, student) {
      student.enrolledSubjects.remove(subjectCode);
    });

    _subjectUpdateController.add(null);
    print("🗑️ Removed exam session: $subjectCode");
  }

  // Add a new student to the main registry
  void addStudentToRegistry({
    required String matric,
    required String surname,
    required String firstname,
    String? studentClass,
  }) {
    if (!_students.containsKey(matric)) {
      _students[matric] = Student(
        matric: matric,
        surname: surname,
        firstname: firstname,
        studentClass: studentClass,
        enrolledSubjects: {}, // Initialize with empty set
      );
      print("✅ Added new student to registry: $matric");
      _subjectUpdateController.add(null);
    } else {
      print("⚠️ Student $matric already exists in registry");
    }
  }
}