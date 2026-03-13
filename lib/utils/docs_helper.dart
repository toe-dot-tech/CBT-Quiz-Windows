import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as path;

class DocxHelper {
  // Extract questions with automatic image embedding
  static Future<List<Map<String, dynamic>>> extractQuestionsFromDocx(
    File file,
  ) async {
    try {
      print("=" * 50);
      print("📄 Starting DOCX extraction: ${file.path}");
      print("=" * 50);

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Step 1: List all files in the archive to see what's inside
      print("\n📋 Files in DOCX archive:");
      int fileCount = 0;
      for (final file in archive) {
        fileCount++;
        if (file.name.startsWith('word/media/')) {
          print("   🖼️ MEDIA: ${file.name}");
        } else if (file.name.contains('xml')) {
          print("   📄 XML: ${file.name}");
        }
      }
      print("   Total files: $fileCount");

      // Step 2: Extract all images from the media folder
      final Map<String, String> imageMap = {};
      final Map<String, String> imageRelations = {};

      int imageCount = 0;
      for (final file in archive) {
        if (file.isFile && file.name.startsWith('word/media/')) {
          imageCount++;
          final fileName = path.basename(file.name);
          final imageBytes = file.content;
          final base64String = base64Encode(imageBytes);
          final extension = fileName.split('.').last.toLowerCase();

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

          imageMap[fileName] = 'data:$mimeType;base64,$base64String';
          print(
            "📸 Found image $imageCount: $fileName (${base64String.length} chars)",
          );
          print(
            "   Preview: ${base64String.substring(0, min(50, base64String.length))}...",
          );
        }
      }
      print("\n📸 TOTAL IMAGES IN DOCX: $imageCount");

      if (imageCount == 0) {
        print(
          "⚠️ No images found in DOCX! Make sure images are embedded in the document.",
        );
      }

      // Step 3: Parse relationships
      print("\n🔗 Parsing relationships...");
      final relsFile = archive.findFile('word/_rels/document.xml.rels');
      if (relsFile != null) {
        final relsXml = utf8.decode(relsFile.content);
        final relsDoc = XmlDocument.parse(relsXml);
        final rels = relsDoc.findAllElements('Relationship');

        for (var rel in rels) {
          final id = rel.getAttribute('Id');
          final target = rel.getAttribute('Target');
          final type = rel.getAttribute('Type');
          if (id != null && target != null) {
            print("   Relationship: $id -> $target (${type ?? 'unknown'})");
            if (target.startsWith('media/')) {
              final fileName = path.basename(target);
              imageRelations[id] = fileName;
              print("   🖼️ Image relationship: $id -> $fileName");
            }
          }
        }
        print("   Total relationships: ${rels.length}");
      } else {
        print("⚠️ No relationships file found!");
      }

      // Step 4: Parse document XML
      print("\n📄 Parsing document XML...");
      final documentFile = archive.findFile('word/document.xml');
      if (documentFile == null) {
        print("❌ No document.xml found!");
        return [];
      }

      final xmlContent = utf8.decode(documentFile.content);
      final document = XmlDocument.parse(xmlContent);

      // Step 5: Find all images in the document
      print("\n🖼️ Searching for images in document...");
      final allDrawings = document.findAllElements('w:drawing');
      print("   Total drawings found: ${allDrawings.length}");

      int imageRefCount = 0;
      for (var drawing in allDrawings) {
        final blips = drawing.findAllElements('a:blip');
        for (var blip in blips) {
          final rId =
              blip.getAttribute('r:embed') ?? blip.getAttribute('r:link');
          if (rId != null) {
            imageRefCount++;
            print("   Image reference $imageRefCount: rId=$rId");
            if (imageRelations.containsKey(rId)) {
              print("      → Maps to: ${imageRelations[rId]}");
            } else {
              print("      ⚠️ No mapping found for rId: $rId");
            }
          }
        }
      }
      print("   Total image references in document: $imageRefCount");

      // Step 6: Extract questions
      print("\n📝 Extracting questions...");
      final questions = <Map<String, dynamic>>[];
      String currentQuestion = "";
      final List<String> currentOptions = [];
      String currentAnswer = "";
      String? currentImage;
      bool collectingOptions = false;
      int questionWithImageCount = 0;

      final paragraphs = document.findAllElements('w:p');
      print("   Total paragraphs: ${paragraphs.length}");

      for (var paragraph in paragraphs) {
        String? paragraphImage;

        // Check for images in this paragraph
        final drawings = paragraph.findAllElements('w:drawing');
        for (var drawing in drawings) {
          final blips = drawing.findAllElements('a:blip');
          for (var blip in blips) {
            final rId =
                blip.getAttribute('r:embed') ?? blip.getAttribute('r:link');
            if (rId != null && imageRelations.containsKey(rId)) {
              final fileName = imageRelations[rId]!;
              if (imageMap.containsKey(fileName)) {
                paragraphImage = imageMap[fileName];
                print("   ✅ Found image for paragraph: $fileName");
              } else {
                print("   ⚠️ Image file not found in map: $fileName");
              }
            }
          }
        }

        // Extract text from paragraph
        final texts = paragraph.findAllElements('w:t');
        String line = texts.map((e) => e.innerText).join().trim();

        if (line.isEmpty && paragraphImage == null) continue;

        if (paragraphImage != null) {
          print("   📸 Paragraph HAS IMAGE");
        }
        if (line.isNotEmpty) {
          print(
            "   📝 Text: '${line.length > 50 ? '${line.substring(0, 50)}...' : line}'",
          );
        }

        // Detect question number
        if (RegExp(r'^\d+[\.\)]').hasMatch(line)) {
          // Save previous question
          if (currentQuestion.isNotEmpty || currentImage != null) {
            if (currentImage != null) questionWithImageCount++;
            questions.add(
              _createQuestionWithImage(
                currentQuestion,
                currentOptions,
                currentAnswer,
                currentImage,
              ),
            );
            print(
              "   ✅ Saved question ${questions.length}${currentImage != null ? ' [WITH IMAGE]' : ''}",
            );
          }
          // Start new question
          currentQuestion = line
              .replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '')
              .trim();
          currentOptions.clear();
          currentAnswer = "";
          currentImage = paragraphImage;
          collectingOptions = false;
          print(
            "   🆕 New question detected: '${currentQuestion.substring(0, min(30, currentQuestion.length))}...'",
          );
        }
        // Detect options
        else if (RegExp(r'^[A-D][\.\)]\s').hasMatch(line)) {
          collectingOptions = true;
          currentOptions.add(line);
          print("   🔘 Option added: $line");
        }
        // Detect answer
        else if (line.contains('ANS:')) {
          currentAnswer = line.split(':').last.trim();
          print("   ✅ Answer detected: $currentAnswer");
        }
        // Continuation
        else {
          if (collectingOptions) {
            if (currentOptions.isNotEmpty) {
              currentOptions[currentOptions.length - 1] += ' $line';
            }
          } else {
            if (currentQuestion.isNotEmpty) {
              currentQuestion += ' $line';
            }
          }
        }

        // Store image if found early
        if (paragraphImage != null &&
            currentQuestion.isEmpty &&
            currentImage == null) {
          currentImage = paragraphImage;
          print("   📸 Stored image for upcoming question");
        }
      }

      // Add last question
      if (currentQuestion.isNotEmpty || currentImage != null) {
        if (currentImage != null) questionWithImageCount++;
        questions.add(
          _createQuestionWithImage(
            currentQuestion,
            currentOptions,
            currentAnswer,
            currentImage,
          ),
        );
        print(
          "   ✅ Saved final question ${questions.length}${currentImage != null ? ' [WITH IMAGE]' : ''}",
        );
      }

      print("\n${"=" * 50}");
      print("📊 EXTRACTION SUMMARY:");
      print("   Total questions: ${questions.length}");
      print(
        "   Questions with images: $questionWithImageCount/${questions.length}",
      );
      print("   Total images in DOCX: $imageCount");
      print("   Image references in document: $imageRefCount");
      print("=" * 50);

      return questions;
    } catch (e) {
      print('❌ Error extracting questions: $e');
      return [];
    }
  }

  static Map<String, dynamic> _createQuestionWithImage(
    String question,
    List<String> options,
    String answer,
    String? imageBase64,
  ) {
    String type = 'OBJ';

    // Theory keywords detection
    final theoryKeywords = [
      'discuss',
      'explain',
      'describe',
      'analyze',
      'elaborate',
      'what are the',
      'why is',
      'how does',
      'compare',
      'contrast',
      'outline',
      'summarize',
      'critically',
      'examine',
      'evaluate',
      'justify',
      'interpret',
      'illustrate',
      'demonstrate',
    ];

    for (var keyword in theoryKeywords) {
      if (question.toLowerCase().contains(keyword)) {
        type = 'THEORY';
        break;
      }
    }

    if (options.isNotEmpty && type != 'THEORY') {
      type = 'OBJ';
    }

    if (answer.isNotEmpty && options.isEmpty && type != 'THEORY') {
      type = 'TYPED';
    }

    // Parse options
    Map<String, String> optMap = {
      'optionA': '',
      'optionB': '',
      'optionC': '',
      'optionD': '',
    };

    for (var option in options) {
      if (option.trim().isEmpty) continue;

      final match = RegExp(r'^([A-D])[\.\)]\s+(.*)$').firstMatch(option);
      if (match != null) {
        final letter = match.group(1)!;
        final text = match.group(2)!.trim();
        optMap['option$letter'] = text;
      }
    }

    // Clean up question
    question = question.replaceAll(RegExp(r'\s+[A-D]\.\s*$'), '').trim();

    return {
      'type': type,
      'text': question,
      'optionA': optMap['optionA'] ?? '',
      'optionB': optMap['optionB'] ?? '',
      'optionC': optMap['optionC'] ?? '',
      'optionD': optMap['optionD'] ?? '',
      'answer': answer.trim(),
      'imageBase64': imageBase64,
    };
  }
}
