import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/medicine.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../barcode_scanner_screen.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcode = TextEditingController();
  final _name = TextEditingController();
  final _tag = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController(text: '0');
  final _manufacturer = TextEditingController();
  final _category = TextEditingController();
  DateTime? _expiryDate;
  bool _rx = false;
  bool _loading = false;

  @override
  void dispose() {
    _barcode.dispose();
    _name.dispose();
    _tag.dispose();
    _description.dispose();
    _price.dispose();
    _quantity.dispose();
    _manufacturer.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final m = Medicine(
        barcode: _barcode.text.trim(),
        name: _name.text.trim(),
        tag: _nullable(_tag.text),
        description: _nullable(_description.text),
        price: double.tryParse(_price.text) ?? 0,
        quantity: int.tryParse(_quantity.text) ?? 0,
        manufacturer: _nullable(_manufacturer.text),
        category: _nullable(_category.text),
        expiryDate: _expiryDate,
        prescriptionRequired: _rx,
      );
      await context.read<AppState>().medicines.create(m);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Эм нэмэгдлээ')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _scan() async {
    if (!BarcodeScannerScreen.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Энэ төхөөрөмж дээр камер дэмжихгүй — гараар бичнэ үү')),
      );
      return;
    }
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && mounted) {
      setState(() => _barcode.text = result);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Эм нэмэх')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _FormSection('Үндсэн мэдээлэл'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _barcode,
                            decoration: const InputDecoration(
                              labelText: 'Баркод *',
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Заавал'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            onPressed: _scan,
                            child: const Icon(Icons.qr_code_scanner, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Нэр *',
                        prefixIcon: Icon(Icons.medication_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Заавал' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tag,
                      decoration: const InputDecoration(
                        labelText: 'Тэмдэглэгээ',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _FormSection('Үнэ ба нөөц'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Үнэ ₮ *',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Заавал'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _quantity,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Тоо ширхэг',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _FormSection('Дэлгэрэнгүй'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _manufacturer,
                      decoration: const InputDecoration(
                        labelText: 'Үйлдвэрлэгч',
                        prefixIcon: Icon(Icons.factory_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(
                        labelText: 'Ангилал',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Тайлбар',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Дуусах хугацаа',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    _expiryDate == null
                                        ? 'Сонгоогүй'
                                        : dateFmt.format(_expiryDate!),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _expiryDate == null
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_information_outlined,
                              size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Жор шаардлагатай',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Switch(
                            value: _rx,
                            onChanged: (v) => setState(() => _rx = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Хадгалах'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
