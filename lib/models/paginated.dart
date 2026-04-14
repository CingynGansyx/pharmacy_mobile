import 'medicine.dart';

class PaginatedMedicines {
  final List<Medicine> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;

  PaginatedMedicines({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginatedMedicines.fromJson(Map<String, dynamic> json) =>
      PaginatedMedicines(
        items: ((json['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Medicine.fromJson)
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 1,
        size: (json['size'] as num?)?.toInt() ?? 20,
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      );
}

class ExcelImportResult {
  final int totalImported;
  final int totalErrors;
  final List<Map<String, dynamic>> imported;
  final List<Map<String, dynamic>> errors;

  ExcelImportResult({
    required this.totalImported,
    required this.totalErrors,
    required this.imported,
    required this.errors,
  });

  factory ExcelImportResult.fromJson(Map<String, dynamic> json) =>
      ExcelImportResult(
        totalImported: (json['totalImported'] as num?)?.toInt() ?? 0,
        totalErrors: (json['totalErrors'] as num?)?.toInt() ?? 0,
        imported: ((json['imported'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        errors: ((json['errors'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
      );
}
