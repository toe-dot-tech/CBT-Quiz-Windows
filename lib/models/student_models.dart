// Student model with mutable enrolled subjects (for server-side)
class Student {
  final String matric;
  final String surname;
  final String firstname;
  final String? studentClass;
  Set<String> enrolledSubjects; // Mutable - can be changed

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

  Subject({
    required this.code,
    required this.title,
    required this.duration,
    required this.questionLimit,
    required this.questionBankFile,
    this.enrolledStudents = const [],
    this.completedStudents = const {},
  });

  Subject copyWith({
    List<String>? enrolledStudents,
    Set<String>? completedStudents,
  }) {
    return Subject(
      code: code,
      title: title,
      duration: duration,
      questionLimit: questionLimit,
      questionBankFile: questionBankFile,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      completedStudents: completedStudents ?? this.completedStudents,
    );
  }
}

// Exam session for a specific subject
class ExamSession {
  final Subject subject;
  final DateTime startTime;
  final Set<String> activeStudents;
  final Map<String, StudentProgress> progress;

  ExamSession({
    required this.subject,
    required this.startTime,
    this.activeStudents = const {},
    this.progress = const {},
  });
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

  StudentProgress({
    required this.matric,
    required this.subjectCode,
    required this.startTime,
    this.endTime,
    this.answers = const {},
    this.currentQuestionIndex = 0,
    this.isCompleted = false,
    this.isSubmitted = false,
  });
}