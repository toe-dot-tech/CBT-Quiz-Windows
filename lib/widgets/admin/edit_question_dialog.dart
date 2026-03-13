import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';

class EditQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final int questionNumber;
  final Function(Map<String, dynamic>) onSave;

  const EditQuestionDialog({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onSave,
  });

  @override
  State<EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  late TextEditingController _questionController;
  late TextEditingController _optionAController;
  late TextEditingController _optionBController;
  late TextEditingController _optionCController;
  late TextEditingController _optionDController;
  late TextEditingController _answerController;

  late String _type;
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.question['text'] ?? '',
    );
    _optionAController = TextEditingController(
      text: widget.question['optionA'] ?? '',
    );
    _optionBController = TextEditingController(
      text: widget.question['optionB'] ?? '',
    );
    _optionCController = TextEditingController(
      text: widget.question['optionC'] ?? '',
    );
    _optionDController = TextEditingController(
      text: widget.question['optionD'] ?? '',
    );
    _answerController = TextEditingController(
      text: widget.question['answer'] ?? '',
    );
    _type = widget.question['type'] ?? 'OBJ';

    // Load existing image if present
    _imageBase64 = widget.question['imageBase64'];
    if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
      print("📸 Edit dialog loaded existing image");
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  // Helper method to safely decode and display image
  Widget _buildImageFromBase64(String base64String) {
    try {
      // Handle both full data URI and raw base64
      String cleanBase64 = base64String;
      if (base64String.contains('base64,')) {
        cleanBase64 = base64String.split('base64,').last;
      }

      // Remove any whitespace or invalid characters
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s'), '');

      // Check if it's a valid base64 string (multiple of 4 length)
      if (cleanBase64.length % 4 != 0) {
        cleanBase64 = cleanBase64.padRight(
          cleanBase64.length + (4 - cleanBase64.length % 4),
          '=',
        );
      }

      final bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        height: 150,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print("❌ Image error in edit dialog: $error");
          return Container(
            height: 150,
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
                  const SizedBox(height: 8),
                  Text(
                    "Image could not be loaded",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print("❌ Error decoding image in edit dialog: $e");
      return Container(
        height: 150,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
              const SizedBox(height: 8),
              Text(
                "Invalid image data",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() => _isLoading = true);

        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final extension = file.path.split('.').last.toLowerCase();

        String mimeType;
        switch (extension) {
          case 'png':
            mimeType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          default:
            mimeType = 'image/png';
        }

        setState(() {
          _imageBase64 = 'data:$mimeType;base64,$base64String';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image loaded successfully"),
            backgroundColor: Colors.green,
          ),
        );

        print("📸 Image loaded, length: ${_imageBase64!.length}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _imageBase64 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Row(
        children: [
          Icon(Icons.edit_note, color: AppColors.darkPrimary),
          const SizedBox(width: 8),
          Text(
            "Edit Question ${widget.questionNumber}",
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Type
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Question Type: ",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _type == 'OBJ'
                            ? Colors.blue.withAlpha(26)
                            : _type == 'TYPED'
                            ? Colors.orange.withAlpha(26)
                            : Colors.purple.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _type,
                        style: TextStyle(
                          color: _type == 'OBJ'
                              ? Colors.blue
                              : _type == 'TYPED'
                              ? Colors.orange
                              : Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Image section
              if (_imageBase64 != null && _imageBase64!.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: _buildImageFromBase64(_imageBase64!),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                "Remove Image",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Add Image Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickImage,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.image, color: AppColors.darkPrimary),
                label: Text(
                  _imageBase64 == null
                      ? "Add Image to Question"
                      : "Replace Image",
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: AppColors.darkPrimary),
                ),
              ),
              const SizedBox(height: 16),

              // Question Text
              const Text(
                "Question Text",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter question text...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                ),
              ),
              const SizedBox(height: 16),

              // Options (for OBJ questions)
              if (_type == 'OBJ') ...[
                const Text(
                  "Options",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOptionField("A", _optionAController),
                const SizedBox(height: 8),
                _buildOptionField("B", _optionBController),
                const SizedBox(height: 8),
                _buildOptionField("C", _optionCController),
                const SizedBox(height: 8),
                _buildOptionField("D", _optionDController),
                const SizedBox(height: 16),
              ],

              // Answer
              const Text(
                "Answer",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_type == 'OBJ')
                DropdownButtonFormField<String>(
                  initialValue: _answerController.text.isNotEmpty
                      ? _answerController.text
                      : null,
                  hint: const Text("Select correct answer"),
                  items: const [
                    DropdownMenuItem(value: "A", child: Text("A")),
                    DropdownMenuItem(value: "B", child: Text("B")),
                    DropdownMenuItem(value: "C", child: Text("C")),
                    DropdownMenuItem(value: "D", child: Text("D")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _answerController.text = value ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                  ),
                )
              else
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    hintText: "Enter correct answer",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                  ),
                ),
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
            print("📸 Saving question with image: ${_imageBase64 != null}");

            final updatedQuestion = Map<String, dynamic>.from(widget.question)
              ..['type'] = _type
              ..['text'] = _questionController.text
              ..['optionA'] = _optionAController.text
              ..['optionB'] = _optionBController.text
              ..['optionC'] = _optionCController.text
              ..['optionD'] = _optionDController.text
              ..['answer'] = _answerController.text
              ..['imageBase64'] = _imageBase64;

            widget.onSave(updatedQuestion);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: const Text("SAVE"),
        ),
      ],
    );
  }

  Widget _buildOptionField(String letter, TextEditingController controller) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.darkPrimary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Option $letter",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
            ),
          ),
        ),
      ],
    );
  }
}
