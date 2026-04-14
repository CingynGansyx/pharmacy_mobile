import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/payment.dart';
import '../models/prescription.dart';
import '../models/server_cart.dart';
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
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _walletCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
  }

  Future<void> _attachPrescription() async {
    final p = await PrescriptionUploadSheet.show(context);
    if (p != null && mounted) setState(() => _prescription = p);
  }

  Future<void> _checkout() async {
    final state = context.read<AppState>();
    if (state.currentUser == null || state.cartEmpty) return;
    setState(() => _loading = true);
    try {
      // 1. Create checkout transaction
      final cart = state.cart!;
      final tx = await state.checkout.checkout(
        userId: state.currentUser!.id,
        items: cart.items
            .map((e) => {'barcode': e.barcode, 'quantity': e.quantity})
            .toList(),
        walletAmount: _paymentMethod == PaymentMethod.wallet
            ? double.tryParse(_walletCtrl.text) ?? 0
            : 0,
        bonusPoints: int.tryParse(_bonusCtrl.text) ?? 0,
        prescriptionId: _prescription?.id,
      );

      // 2. Create payment
      final cashPaid = tx.cashPaid;
      Payment? payment;
      if (cashPaid > 0 &&
          _paymentMethod != PaymentMethod.cash &&
          _paymentMethod != PaymentMethod.wallet) {
        payment = await state.payments.create(
          transactionId: tx.id,
          userId: state.currentUser!.id,
          method: _paymentMethod,
          amount: cashPaid,
        );
      }

      // 3. Clear server cart + refresh user
      await state.clearCart();
      _prescription = null;
      await state.refreshCurrentUser();
      if (!mounted) return;

      // 4. Show result
      if (payment != null && payment.isPending) {
        await _showPaymentSheet(payment);
      } else {
        await _showSuccessDialog(tx.total, tx.cashPaid, tx.walletUsed,
            tx.bonusUsed, tx.bonusEarned);
      }
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

  Future<void> _showSuccessDialog(double total, double cashPaid,
      double walletUsed, int bonusUsed, int bonusEarned) async {
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
                Text('Амжилттай',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _summaryRow('Нийт', formatCurrency(total), bold: true),
                _summaryRow('Бэлнээр', formatCurrency(cashPaid)),
                _summaryRow('Хэтэвчнээс', formatCurrency(walletUsed)),
                _summaryRow('Бонус ашигласан', '$bonusUsed'),
                _summaryRow('Бонус олсон', '+$bonusEarned',
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
  }

  Future<void> _showPaymentSheet(Payment payment) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaymentInfoSheet(
        payment: payment,
        onConfirm: () async {
          final state = context.read<AppState>();
          final confirmed = await state.payments.confirm(payment.id);
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(confirmed.isConfirmed
                  ? 'Төлбөр баталгаажлаа'
                  : 'Төлбөр: ${confirmed.status}'),
            ),
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
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
    if (state.cartEmpty) {
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
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text('Сагс хоосон',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Эмийн жагсаалтаас сонгоод нэмнэ үү',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    final items = state.cart!.items;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _CartEntryCard(entry: items[i], state: state),
          ),
        ),
        _BottomPanel(
          state: state,
          loading: _loading,
          prescription: _prescription,
          onAttachPrescription: _attachPrescription,
          walletCtrl: _walletCtrl,
          bonusCtrl: _bonusCtrl,
          paymentMethod: _paymentMethod,
          onPaymentMethodChanged: (m) => setState(() => _paymentMethod = m),
          onCheckout: _checkout,
        ),
      ],
    );
  }
}

class _CartEntryCard extends StatelessWidget {
  const _CartEntryCard({required this.entry, required this.state});
  final CartEntry entry;
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
                  Text(entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(formatCurrency(entry.price),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QuantityStepper(entry: entry, state: state),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.entry, required this.state});
  final CartEntry entry;
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
          _StepperBtn(
            icon: entry.quantity <= 1 ? Icons.delete_outline : Icons.remove,
            onTap: () {
              if (entry.quantity <= 1) {
                state.removeCartItem(entry.barcode);
              } else {
                state.updateCartItem(entry.barcode, entry.quantity - 1);
              }
            },
          ),
          SizedBox(
            width: 28,
            child: Text('${entry.quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          _StepperBtn(
            icon: Icons.add,
            onTap: () =>
                state.updateCartItem(entry.barcode, entry.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
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

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.state,
    required this.loading,
    required this.prescription,
    required this.onAttachPrescription,
    required this.walletCtrl,
    required this.bonusCtrl,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.onCheckout,
  });

  final AppState state;
  final bool loading;
  final Prescription? prescription;
  final VoidCallback onAttachPrescription;
  final TextEditingController walletCtrl;
  final TextEditingController bonusCtrl;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prescription attach (optional)
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onAttachPrescription,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: prescription == null
                        ? AppColors.borderSoft
                        : AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        prescription == null
                            ? Icons.medical_information_outlined
                            : Icons.check_circle,
                        size: 18,
                        color: prescription == null
                            ? AppColors.textMuted
                            : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prescription == null
                              ? 'Эмчийн бичиг хавсаргах (Rx эмд хэрэгтэй)'
                              : 'Жор: ${prescription!.originalFileName ?? prescription!.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: prescription == null
                                ? AppColors.textSecondary
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Payment method selector
              const Text('Төлбөрийн арга',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: PaymentMethod.values.map((m) {
                  final selected = m == paymentMethod;
                  return ChoiceChip(
                    label: Text(paymentMethodLabel(m)),
                    selected: selected,
                    onSelected: (_) => onPaymentMethodChanged(m),
                    avatar: Icon(_iconFor(m), size: 16),
                    selectedColor: AppColors.primarySoft,
                    side: selected
                        ? const BorderSide(color: AppColors.primary)
                        : BorderSide.none,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Wallet / bonus fields (show when relevant)
              if (paymentMethod == PaymentMethod.wallet) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: walletCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Хэтэвчнээс', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: bonusCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Бонус', isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Total + checkout
              Row(
                children: [
                  const Text('Нийт',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(formatCurrency(state.cartTotal),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
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
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Төлбөр төлөх'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case PaymentMethod.qpay:
        return Icons.qr_code_2;
    }
  }
}

/// Bottom sheet showing bank transfer or QPay info.
class _PaymentInfoSheet extends StatelessWidget {
  const _PaymentInfoSheet({
    required this.payment,
    required this.onConfirm,
  });

  final Payment payment;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              payment.method == PaymentMethod.qpay
                  ? 'QPay төлбөр'
                  : 'Дансны шилжүүлэг',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Дүн: ${formatCurrency(payment.amount)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 24),
            if (payment.method == PaymentMethod.qpay &&
                payment.qrCodeData != null) ...[
              const Text('QR кодыг уншуулж төлнө үү',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Center(
                child: bw.BarcodeWidget(
                  barcode: bw.Barcode.qrCode(),
                  data: payment.qrCodeData!,
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                payment.qrCodeData!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
            if (payment.method == PaymentMethod.bankTransfer) ...[
              _InfoRow('Банк', payment.bankName ?? '—'),
              _InfoRow('Данс', payment.bankAccount ?? '—'),
              _InfoRow('Гүйлгээний утга', payment.referenceNote ?? '—'),
              const SizedBox(height: 8),
              const Text(
                'Дээрх мэдээллээр шилжүүлэг хийсний дараа "Баталгаажуулах" дарна уу.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onConfirm,
              child: const Text('Баталгаажуулах'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Хаах'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
