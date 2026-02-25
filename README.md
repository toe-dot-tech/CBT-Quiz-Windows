# 🚀 **CBT Examination System for Windows**

![Flutter](https://img.shields.io/badge/Flutter-3.13-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.1-teal?logo=dart)
![Windows](https://img.shields.io/badge/Windows-10|11-success?logo=windows)
![License](https://img.shields.io/badge/License-MIT-yellow)

A **production-ready, offline-first Computer-Based Testing (CBT) system** for Windows that enables institutions to conduct secure, monitored digital examinations without internet dependency. Built with Flutter for native performance and reliability.

---

## 📋 **Table of Contents**
- [✨ Key Features](#-key-features)
- [🖼️ Screenshots](#️-screenshots)
- [⚙️ Architecture](#️-architecture)
- [📦 Installation](#-installation)
- [🎯 Usage Guide](#-usage-guide)
- [🛠️ Technical Stack](#️-technical-stack)
- [📁 Project Structure](#-project-structure)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [📬 Contact](#-contact)

---

## ✨ **Key Features**

### 🎓 **For Administrators**
- **Complete Exam Control** – Start/stop exams, configure duration, question limits
- **Real-Time Monitoring** – Live dashboard showing student progress and submissions
- **Bulk Student Upload** – Import 1000+ students via CSV (matric, surname, firstname, class)
- **Question Bank Management** – Import from DOCX files with automatic parsing
- **Live Statistics** – Pass/fail counts, average scores, submission status
- **Performance Charts** – Visual representation of exam results
- **CSV Report Export** – Download complete results with pass/fail status
- **Live Activity Log** – See exactly what each student is doing in real-time

### 👨‍🎓 **For Students**
- **Simple Login** – Matric number and surname authentication
- **Clean Interface** – Distraction-free exam environment
- **Question Navigator** – Move between questions with progress tracking
- **Timer Display** – Countdown with urgent warning (last minute)
- **Auto-Submit** – Automatic submission when time expires
- **Progress Pings** – Admin sees your progress in real-time
- **Multi-Question Types** – Supports OBJ (multiple choice), GERMAN (typed answers), THEORY (instructions)

### 🏗️ **Technical Excellence**
- **Offline-First** – Zero internet dependency (uses local network only)
- **Embedded Server** – Built-in HTTP server serves student UI via web browser
- **Custom CSV Parser** – Zero external dependencies for file parsing
- **DOCX Question Import** – Extract questions formatted with numbers and options
- **Real-Time Updates** – Live student activity without polling
- **Cross-Platform Ready** – Windows desktop app + web-based student interface

---

## 🖼️ **Screenshots**

| Admin Dashboard | Student Login | Exam Interface |
|:---:|:---:|:---:|
| ![Admin Dashboard](assets/screenshots/admin-dashboard.png) | ![Student Login](assets/screenshots/student-login.png) | ![Exam Interface](assets/screenshots/exam-interface.png) |
| *Real-time stats and controls* | *Secure student authentication* | *Clean exam-taking experience* |

> **Note**: Add actual screenshots to the `assets/screenshots/` folder

---

## ⚙️ **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    WINDOWS DESKTOP APP                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  Admin View  │  │ Student View │  │  Quiz Provider   │   │
│  │  (Controls)  │  │  (Interface) │  │  (State Management)│   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘   │
│         │                  │                   │              │
│         └──────────────────┼───────────────────┘              │
│                            ▼                                   │
│  ┌─────────────────────────────────────────────────────┐     │
│  │              Quiz Server (Embedded)                  │     │
│  │  - REST API for student login/progress/submission   │     │
│  │  - Serves static web assets                          │     │
│  └─────────────────────┬───────────────────────────────┘     │
└────────────────────────┼──────────────────────────────────────┘
                         │ (Port 8080)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 STUDENT WEB BROWSER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │    Login     │  │    Exam      │  │   Submission     │   │
│  │   Interface  │  │   Taking     │  │   Confirmation   │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow
1. **Admin starts server** → Embedded HTTP server launches on port 8080
2. **Students connect** via browser to `http://[admin-ip]:8080`
3. **Login verification** → Server checks credentials against `registered_students.csv`
4. **Exam begins** → Questions served from `questions.csv` with configured limit
5. **Real-time updates** → Student progress sent to admin dashboard
6. **Submission** → Results saved to `quiz_results.csv` with timestamp

---

## 📦 **Installation**

### Prerequisites
- Windows 10 or 11 (64-bit)
- No internet connection required for exam execution

### Method 1: Download Pre-built EXE (Recommended)
1. Go to [Releases](https://github.com/toe-dot-tech/CBT-Quiz-Windows/releases)
2. Download `CBT-Quiz-Setup.exe`
3. Run the installer
4. Launch from desktop shortcut

### Method 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/toe-dot-tech/CBT-Quiz-Windows.git
cd CBT-Quiz-Windows

# Get dependencies
flutter pub get

# Build Windows executable
flutter build windows --release

# The executable is at: build\windows\x64\runner\Release\cbtapp.exe
```

### Method 3: Run in Development Mode
```bash
flutter run -d windows
```

---

## 🎯 **Usage Guide**

### 🚀 **Quick Start**

1. **Launch the application** (double-click `cbtapp.exe`)
2. **Click "START EXAM"** in the sidebar
3. **Note the IP address** displayed (e.g., `http://192.168.1.100:8080`)
4. **Students connect** using any device with a browser
5. **Monitor progress** in real-time from the admin dashboard

### 📝 **Setting Up Questions**

#### Option A: Import from DOCX
1. Format your document:
   ```
   1. What is Flutter?
   A. A framework
   B. A language
   C. A database
   D. A game
   ANS: A

   2. Next question...
   ```
2. Click **"Import DOCX File"** in sidebar
3. Select your file

#### Option B: Manual Addition
1. Click **"Add Single Q"** in sidebar
2. Fill in question, options, and answer
3. Click **"SAVE QUESTION"**

### 👥 **Adding Students**

1. Prepare a CSV file:
```csv
Matric,Surname,Firstname,Class
2024001,OKAFOR,John,SS 3
2024002,ADELEKE,Sarah,SS 3
```
2. Click **"Bulk Student Upload"**
3. Select your CSV file

### 📊 **Exam Configuration**

Click **"Exam Config"** to set:
- **Course Title** (e.g., "Mathematics 101")
- **Time (Minutes)** (e.g., "60")
- **Question Limit** (e.g., "50")

### 📈 **Monitoring Live Exam**

The dashboard shows:
- **Registered** – Total students in registry
- **Finished** – Completed submissions
- **Avg. Score** – Running average
- **Question Bank** – Available questions
- **Submission Status** – e.g., "23 / 45" completed
- **Live Activity Log** – Real-time student actions
- **Performance Chart** – Pass/fail visualization

### 📥 **Exporting Results**

Click **"Final Report (CSV)"** to download a formatted report with:
- Serial numbers
- Matric numbers
- Student names
- Scores (%)
- Pass/Fail status

---

## 🛠️ **Technical Stack**

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend (Admin)** | Flutter Windows | Native desktop UI |
| **Frontend (Student)** | Flutter Web | Browser-based interface |
| **State Management** | Riverpod | Reactive state handling |
| **HTTP Server** | Shelf | Embedded REST API |
| **File Parsing** | Custom CSV/DOCX | Zero external dependencies |
| **File Picking** | file_picker | Native Windows dialogs |
| **Charts** | fl_chart | Performance visualization |
| **Archive** | archive | DOCX extraction |

---

## 📁 **Project Structure**

```
cbtapp/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── models/                   # Data models
│   │   ├── quiz_models.dart
│   │   └── student_models.dart
│   ├── providers/                 # State management
│   │   ├── quiz_provider.dart
│   │   └── timer_provider.dart
│   ├── server/                    # Embedded HTTP server
│   │   └── quiz_server.dart
│   ├── services/                  # Business logic
│   │   └── result_storage_service.dart
│   ├── utils/                      # Utilities
│   │   ├── csv_helper.dart
│   │   ├── docs_helper.dart
│   │   ├── file_picker_helper.dart
│   │   └── path_helper.dart
│   ├── views/                      # UI Screens
│   │   ├── admin/
│   │   │   └── admin_view.dart
│   │   └── student/
│   │       ├── student_view.dart
│   │       └── student_quiz_view.dart
│   └── widgets/                     # Reusable components
│       └── custom_chart.dart
├── assets/
│   └── web/                         # Student web interface
│       ├── index.html
│       ├── main.dart.js
│       └── ...
├── windows/                          # Windows-specific code
├── questions.csv                     # Question bank
├── registered_students.csv           # Student registry
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

---

## 🧪 **Testing**

### Test Credentials
Use these sample students for testing:

| Matric | Surname | Class |
|--------|---------|-------|
| 2024001 | OKAFOR | SS 3 |
| 2024002 | ADELEKE | SS 3 |
| 2024003 | MUSA | SS 3 |

### Sample Questions
The included `questions.csv` contains sample questions to get started.

---

## 🤝 **Contributing**

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow [Flutter style guide](https://flutter.dev/docs/development/tools/formatting)
- Write meaningful commit messages
- Update documentation for new features
- Add tests when applicable

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📬 **Contact**

**Developer:** TOE Tech

- **GitHub:** [@toe-dot-tech](https://github.com/toe-dot-tech)
- **X:** [toetech_](https://x.com/toetech_)
- **Project Link:** [https://github.com/toe-dot-tech/CBT-Quiz-Windows](https://github.com/toe-dot-tech/CBT-Quiz-Windows)

---

## ⭐ **Support**

If you find this project useful, please consider giving it a star on GitHub! It helps others discover this solution.

---

## 🙏 **Acknowledgments**

- Flutter team for an amazing framework
- Riverpod for elegant state management
- All contributors and testers

---

**Built with ❤️ for education**