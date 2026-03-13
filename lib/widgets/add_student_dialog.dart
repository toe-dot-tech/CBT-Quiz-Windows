import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';

class AddStudentToSessionDialog extends StatefulWidget {
  final String subjectCode;
  final String subjectTitle;
  final Function(String, String, String, String) onAdd;
  final List<Map<String, dynamic>> allStudents; // For search functionality

  const AddStudentToSessionDialog({
    super.key,
    required this.subjectCode,
    required this.subjectTitle,
    required this.onAdd,
    required this.allStudents,
  });

  @override
  State<AddStudentToSessionDialog> createState() =>
      _AddStudentToSessionDialogState();
}

class _AddStudentToSessionDialogState extends State<AddStudentToSessionDialog> {
  final _matricController = TextEditingController();
  final _surnameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _classController = TextEditingController();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearch = false;

  @override
  void dispose() {
    _matricController.dispose();
    _surnameController.dispose();
    _firstnameController.dispose();
    _classController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchStudents(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = widget.allStudents.where((student) {
      final matric = student['matric'].toLowerCase();
      final surname = student['surname'].toLowerCase();
      final firstname = student['firstname'].toLowerCase();
      final searchLower = query.toLowerCase();

      return matric.contains(searchLower) ||
          surname.contains(searchLower) ||
          firstname.contains(searchLower);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  void _selectStudent(Map<String, dynamic> student) {
    setState(() {
      _matricController.text = student['matric'];
      _surnameController.text = student['surname'];
      _firstnameController.text = student['firstname'];
      _classController.text = student['class'] ?? '';
      _showSearch = false;
      _searchController.clear();
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Text(
        "Add Student to ${widget.subjectTitle}",
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle between search and manual entry
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          _searchController.clear();
                          _searchResults = [];
                        });
                      },
                      child: Text(
                        _showSearch
                            ? "Manual Entry"
                            : "Search Existing Student",
                        style: TextStyle(color: AppColors.darkPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_showSearch) ...[
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchStudents,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Search by matric, surname...",
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.darkPrimary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search results
                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final student = _searchResults[index];
                        return InkWell(
                          onTap: () => _selectStudent(student),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkPrimary.withAlpha(26),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      student['surname'][0],
                                      style: TextStyle(
                                        color: AppColors.darkPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${student['surname']} ${student['firstname']}",
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        student['matric'],
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],

              // Manual entry fields
              if (!_showSearch) ...[
                _buildField(_matricController, "Matric Number", Icons.badge),
                const SizedBox(height: 12),
                _buildField(_surnameController, "Surname", Icons.person),
                const SizedBox(height: 12),
                _buildField(
                  _firstnameController,
                  "First Name",
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildField(
                  _classController,
                  "Class (e.g., SS 3)",
                  Icons.class_,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "CANCEL",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_matricController.text.isNotEmpty &&
                _surnameController.text.isNotEmpty &&
                _firstnameController.text.isNotEmpty) {
              widget.onAdd(
                _matricController.text.trim().toUpperCase(),
                _surnameController.text.trim().toUpperCase(),
                _firstnameController.text.trim(),
                _classController.text.trim(),
              );
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Matric, Surname, and Firstname are required"),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: const Text("ADD STUDENT"),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.darkPrimary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
