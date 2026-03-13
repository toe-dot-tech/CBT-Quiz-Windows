import 'dart:convert';

class CsvHelper {
  // Manual CSV parser with proper quote handling
  static List<List<String>> parseCsv(String csvString) {
    List<List<String>> result = [];
    LineSplitter ls = const LineSplitter();
    List<String> lines = ls.convert(csvString);

    for (String line in lines) {
      if (line.trim().isEmpty) continue;

      // Handle quoted fields (for base64 images)
      List<String> row = [];
      StringBuffer currentField = StringBuffer();
      bool inQuotes = false;

      for (int i = 0; i < line.length; i++) {
        String char = line[i];

        if (char == '"' && (i == 0 || line[i - 1] != '\\')) {
          inQuotes = !inQuotes;
        } else if (char == ',' && !inQuotes) {
          // End of field
          row.add(currentField.toString().trim());
          currentField.clear();
        } else {
          currentField.write(char);
        }
      }

      // Add the last field
      row.add(currentField.toString().trim());

      result.add(row);
    }

    return result;
  }

  // Convert data to CSV string with proper escaping
  static String listToCsv(List<List<dynamic>> data) {
    StringBuffer buffer = StringBuffer();
    for (var row in data) {
      for (int i = 0; i < row.length; i++) {
        if (i > 0) buffer.write(',');
        // Convert each item to String explicitly
        buffer.write(_escapeCsvField(row[i].toString()));
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  // Escape CSV field (especially important for base64 data)
  static String _escapeCsvField(String field) {
    // Always quote fields that contain special characters OR are very long (base64)
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r') ||
        field.length > 1000) {
      // Escape quotes by doubling them
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Parse CSV to List<Map<String, dynamic>> with headers
  static List<Map<String, dynamic>> parseCsvToMap(
    String csvString, {
    bool hasHeader = true,
  }) {
    final rows = parseCsv(csvString);
    if (rows.isEmpty) return [];

    if (hasHeader) {
      final headers = rows.first;
      final dataRows = rows.skip(1).where((row) => row.isNotEmpty).toList();

      return dataRows.map((row) {
        Map<String, dynamic> map = {};
        for (int i = 0; i < headers.length && i < row.length; i++) {
          map[headers[i].toLowerCase()] = row[i];
        }
        return map;
      }).toList();
    } else {
      return rows.map((row) {
        Map<String, dynamic> map = {};
        for (int i = 0; i < row.length; i++) {
          map['col$i'] = row[i];
        }
        return map;
      }).toList();
    }
  }

  // Helper method to validate CSV structure
  static void validateCsv(String csvString) {
    final rows = parseCsv(csvString);
    print("📊 CSV Validation:");
    print("   Total rows: ${rows.length}");
    if (rows.isNotEmpty) {
      print("   Columns in header: ${rows.first.length}");
      for (int i = 1; i < rows.length && i < 5; i++) {
        print("   Row $i columns: ${rows[i].length}");
        // Check for potential image data
        if (rows[i].length > 7 &&
            rows[i][7].toString().startsWith('data:image')) {
          print("   ✅ Row $i contains valid image data");
        }
      }
    }
  }
}
