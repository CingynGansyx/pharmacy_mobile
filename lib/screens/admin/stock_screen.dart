import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/medicine.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../barcode_scanner_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _barcode = TextEditingController();
  final _amount = TextEditingController(text: '1');
  Medicine? _found;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _barcode.dispose();
    _amount.dispose();
    super.dispose();
  }

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
    if (result == null || !mounted) return;
    _barcode.text = result;
    await _lookup();
  }

  Future<void> _lookup() async {
    final code = _barcode.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _found = null;
    });
    try {
      final m = await context.read<AppState>().medicines.byBarcode(code);
      if (m == null) {
        setState(() => _error = 'Энэ баркодтой эм олдсонгүй');
      } else {
        setState(() => _found = m);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addStock() async {
    final amount = int.tryParse(_amount.text);
    if (amount == null || amount <= 0 || _found == null) return;
    setState(() => _loading = true);
    try {
      final updated = await context
          .read<AppState>()
          .medicines
          .addStock(_found!.barcode, amount);
      setState(() => _found = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Нөөц нэмэгдлээ — одоо: ${updated.quantity} ширхэг')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Баркод оруулах',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcode,
                        decoration: const InputDecoration(
                          hintText: 'Гараар бичих',
                          prefixIcon: Icon(Icons.qr_code, size: 20),
                        ),
                        onSubmitted: (_) => _lookup(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: _scan,
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Скан'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _lookup,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Хайх'),
                  ),
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
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_found != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.medication,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _found!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Үлдэгдэл: ${_found!.quantity} ширхэг · ${formatCurrency(_found!.price)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  const Divider(height: 24),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Нэмэх тоо ширхэг',
                      prefixIcon: Icon(Icons.add_box_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _addStock,
                      icon: const Icon(Icons.add),
                      label: const Text('Нөөц нэмэх'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Нөөц нэмэх')),
      body: body,
    );
  }
}
