import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/paginated.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  PlatformFile? _file;
  bool _loading = false;
  ExcelImportResult? _result;
  String? _error;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() {
        _file = result.files.first;
        _result = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Файл сонгох алдаа: $e');
    }
  }

  Future<void> _import() async {
    if (_file == null || _file!.bytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await context.read<AppState>().medicines.importExcel(
            fileName: _file!.name,
            fileBytes: _file!.bytes!,
          );
      setState(() => _result = r);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Алдаа: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excel импорт')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Эмийн бүртгэлийг Excel файлаар импортлох',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Файл .xlsx форматтай, толгой мөрөнд: barcode, name, price, quantity гэх мэт баганууд байна.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _file != null
                            ? AppColors.primarySoft
                            : AppColors.borderSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _file != null
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _file == null
                                ? Icons.upload_file
                                : Icons.description,
                            color: _file == null
                                ? AppColors.textMuted
                                : AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _file == null
                                      ? 'Excel файл сонгох'
                                      : _file!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _file == null
                                      ? '.xlsx, .xls'
                                      : '${(_file!.size / 1024).toStringAsFixed(1)} KB',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        (_file == null || _loading) ? null : _import,
                    icon: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload),
                    label: const Text('Импортлох'),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final ExcelImportResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Импорт дууслаа',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${result.totalImported} амжилттай · ${result.totalErrors} алдаа',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (result.imported.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('Нэмэгдсэн',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              for (final item in result.imported)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item['action'] == 'created'
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.info.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          item['action'] == 'created'
                              ? 'Шинэ'
                              : 'Нөөц+',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item['action'] == 'created'
                                ? AppColors.primary
                                : AppColors.info,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['name']} (${item['barcode']})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (result.errors.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('Алдаанууд',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger)),
              const SizedBox(height: 6),
              for (final err in result.errors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Мөр ${err['row']}: ${err['error']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.danger),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
