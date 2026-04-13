import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/prescription.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PrescriptionUploadSheet extends StatefulWidget {
  const PrescriptionUploadSheet({super.key});

  @override
  State<PrescriptionUploadSheet> createState() =>
      _PrescriptionUploadSheetState();

  static Future<Prescription?> show(BuildContext context) {
    return showModalBottomSheet<Prescription>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PrescriptionUploadSheet(),
    );
  }
}

class _PrescriptionUploadSheetState extends State<PrescriptionUploadSheet> {
  final _doctor = TextEditingController();
  final _notes = TextEditingController();
  PlatformFile? _file;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _doctor.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _file = result.files.first);
    } catch (e) {
      setState(() => _error = 'Файл сонгох алдаа: $e');
    }
  }

  Future<void> _upload() async {
    final state = context.read<AppState>();
    final userId = state.currentUser?.id;
    if (userId == null) return;
    if (_file == null || _file!.bytes == null) {
      setState(() => _error = 'Эхлээд файл сонгоно уу');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await state.prescriptions.upload(
        userId: userId,
        fileName: _file!.name,
        fileBytes: _file!.bytes!,
        contentType: _contentTypeFor(_file!.extension),
        doctorName: _doctor.text.trim(),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(p);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Алдаа: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _contentTypeFor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 20 + viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.medical_information,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Эмчийн бичиг',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Жороо хуулж оруулна уу',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    style: _file == null
                        ? BorderStyle.solid
                        : BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _file == null
                          ? Icons.cloud_upload_outlined
                          : Icons.check_circle,
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
                                ? 'Файл сонгох'
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
                                ? 'PDF, JPG, PNG'
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
            TextField(
              controller: _doctor,
              decoration: const InputDecoration(
                labelText: 'Эмчийн нэр',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Тэмдэглэл',
                alignLabelWithHint: true,
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
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _upload,
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
              label: const Text('Хуулж оруулах'),
            ),
          ],
        ),
      ),
    );
  }
}
