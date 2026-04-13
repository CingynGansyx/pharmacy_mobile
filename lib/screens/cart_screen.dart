import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/cart_item.dart';
import '../models/prescription.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'prescription_upload_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _walletCtrl = TextEditingController(text: '0');
  final _bonusCtrl = TextEditingController(text: '0');
  bool _loading = false;
  Prescription? _prescription;

  @override
  void dispose() {
    _walletCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
  }

  bool get _needsPrescription =>
      context.read<AppState>().cart.any((c) => c.medicine.prescriptionRequired);

  Future<void> _attachPrescription() async {
    final p = await PrescriptionUploadSheet.show(context);
    if (p != null && mounted) setState(() => _prescription = p);
  }

  Future<void> _checkout() async {
    final state = context.read<AppState>();
    if (state.currentUser == null || state.cart.isEmpty) return;
    if (_needsPrescription && _prescription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Жор шаардлагатай эм байна — эмчийн бичиг хавсаргана уу'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final tx = await state.checkout.checkout(
        userId: state.currentUser!.id,
        items: state.cart,
        walletAmount: double.tryParse(_walletCtrl.text) ?? 0,
        bonusPoints: int.tryParse(_bonusCtrl.text) ?? 0,
        prescriptionId: _prescription?.id,
      );
      state.clearCart();
      _prescription = null;
      await state.refreshCurrentUser();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: AppColors.success, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Амжилттай',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _summaryRow('Нийт', formatCurrency(tx.total), bold: true),
                  _summaryRow('Бэлнээр', formatCurrency(tx.cashPaid)),
                  _summaryRow(
                      'Хэтэвчнээс', formatCurrency(tx.walletUsed)),
                  _summaryRow('Бонус ашигласан', '${tx.bonusUsed}'),
                  _summaryRow('Бонус олсон', '+${tx.bonusEarned}',
                      color: AppColors.success),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Болсон'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Алдаа: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Сагс хоосон',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Эмийн жагсаалтаас сонгоод нэмнэ үү',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: state.cart.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _CartItemCard(item: state.cart[i], state: state),
          ),
        ),
        _BottomCheckoutPanel(
          state: state,
          loading: _loading,
          needsPrescription: _needsPrescription,
          prescription: _prescription,
          onAttachPrescription: _attachPrescription,
          walletCtrl: _walletCtrl,
          bonusCtrl: _bonusCtrl,
          onCheckout: _checkout,
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item, required this.state});

  final CartItem item;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.medication,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(item.medicine.price),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QuantityStepper(item: item, state: state),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.item, required this.state});

  final CartItem item;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.borderSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: () => state.setCartQuantity(
                item.medicine.barcode, item.quantity - 1),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: () => state.setCartQuantity(
                item.medicine.barcode, item.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _BottomCheckoutPanel extends StatelessWidget {
  const _BottomCheckoutPanel({
    required this.state,
    required this.loading,
    required this.needsPrescription,
    required this.prescription,
    required this.onAttachPrescription,
    required this.walletCtrl,
    required this.bonusCtrl,
    required this.onCheckout,
  });

  final AppState state;
  final bool loading;
  final bool needsPrescription;
  final Prescription? prescription;
  final VoidCallback onAttachPrescription;
  final TextEditingController walletCtrl;
  final TextEditingController bonusCtrl;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSoft),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (needsPrescription) ...[
                _PrescriptionCard(
                  prescription: prescription,
                  onTap: onAttachPrescription,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: walletCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Хэтэвчнээс',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: bonusCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Бонус',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Нийт',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatCurrency(state.cartTotal),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: loading ? null : onCheckout,
                icon: loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Төлбөр төлөх'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.prescription, required this.onTap});

  final Prescription? prescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attached = prescription != null;
    final color = attached ? AppColors.success : AppColors.warning;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              attached ? Icons.check_circle : Icons.warning_amber_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attached
                        ? 'Эмчийн бичиг хавсрагдсан'
                        : 'Эмчийн бичиг шаардлагатай',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (attached)
                    Text(
                      prescription!.originalFileName ?? prescription!.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    const Text(
                      'Сагсанд Rx эм байна',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              attached ? 'Солих' : 'Хавсаргах',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
