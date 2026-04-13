import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<List<AppTransaction>> _txFuture;

  @override
  void initState() {
    super.initState();
    _txFuture = _load();
  }

  Future<List<AppTransaction>> _load() {
    final state = context.read<AppState>();
    final id = state.currentUser?.id;
    if (id == null) return Future.value(const []);
    return state.users.transactions(id);
  }

  void _reloadTransactions() {
    setState(() => _txFuture = _load());
  }

  Future<void> _amountDialog({required bool deposit}) async {
    final ctrl = TextEditingController();
    try {
      final res = await showDialog<double>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(deposit ? 'Хэтэвч цэнэглэх' : 'Хэтэвчнээс гаргах'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Дүн',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Болих'),
            ),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text);
                if (v != null && v > 0) Navigator.pop(context, v);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (res == null || !mounted) return;
      final state = context.read<AppState>();
      final id = state.currentUser?.id;
      if (id == null) return;
      try {
        if (deposit) {
          await state.users.deposit(id, res);
        } else {
          await state.users.withdraw(id, res);
        }
        await state.refreshCurrentUser();
        if (!mounted) return;
        _reloadTransactions();
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Алдаа: $e')));
      }
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();
    if (user.role != UserRole.customer) {
      return const Center(child: Text('Хэтэвчийн хэсэг зөвхөн хэрэглэгчид'));
    }
    return RefreshIndicator(
      onRefresh: () async {
        await state.refreshCurrentUser();
        _reloadTransactions();
        await _txFuture;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _BalanceCard(
            balance: user.wallet.balance,
            bonus: user.bonusPoints,
            onDeposit: () => _amountDialog(deposit: true),
            onWithdraw: () => _amountDialog(deposit: false),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Гүйлгээний түүх',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<AppTransaction>>(
            future: _txFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                final err = snap.error;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    err is ApiException ? err.message : 'Алдаа: $err',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                );
              }
              final list = snap.data ?? const [];
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Text(
                    'Гүйлгээ байхгүй',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return Column(
                children: [
                  for (final t in list) _TransactionTile(tx: t),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.bonus,
    required this.onDeposit,
    required this.onWithdraw,
  });

  final double balance;
  final int bonus;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Үлдэгдэл',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$bonus',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OnCardButton(
                  icon: Icons.add,
                  label: 'Цэнэглэх',
                  primary: true,
                  onTap: onDeposit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OnCardButton(
                  icon: Icons.remove,
                  label: 'Гаргах',
                  primary: false,
                  onTap: onWithdraw,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnCardButton extends StatelessWidget {
  const _OnCardButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? Colors.white : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: primary ? AppColors.primary : Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primary ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final AppTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TxType.walletDeposit;
    final isExpense = tx.type == TxType.walletWithdraw ||
        tx.type == TxType.sale;
    final amountColor = isIncome
        ? AppColors.success
        : isExpense
            ? AppColors.textPrimary
            : AppColors.textSecondary;
    final amountPrefix = isIncome ? '+' : isExpense ? '−' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _bgFor(tx.type),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _iconFor(tx.type),
                  color: _colorFor(tx.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelFor(tx.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.dateTime == null
                          ? ''
                          : dateTimeFmt.format(tx.dateTime!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$amountPrefix${formatCurrency(tx.total)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bgFor(TxType t) {
    switch (t) {
      case TxType.sale:
        return AppColors.primarySoft;
      case TxType.purchase:
        return AppColors.info.withValues(alpha: 0.1);
      case TxType.walletDeposit:
        return AppColors.success.withValues(alpha: 0.1);
      case TxType.walletWithdraw:
        return AppColors.warning.withValues(alpha: 0.1);
      case TxType.unknown:
        return AppColors.borderSoft;
    }
  }

  Color _colorFor(TxType t) {
    switch (t) {
      case TxType.sale:
        return AppColors.primary;
      case TxType.purchase:
        return AppColors.info;
      case TxType.walletDeposit:
        return AppColors.success;
      case TxType.walletWithdraw:
        return AppColors.warning;
      case TxType.unknown:
        return AppColors.textMuted;
    }
  }

  IconData _iconFor(TxType t) {
    switch (t) {
      case TxType.sale:
        return Icons.shopping_bag_outlined;
      case TxType.purchase:
        return Icons.local_shipping_outlined;
      case TxType.walletDeposit:
        return Icons.arrow_downward;
      case TxType.walletWithdraw:
        return Icons.arrow_upward;
      case TxType.unknown:
        return Icons.help_outline;
    }
  }

  String _labelFor(TxType t) {
    switch (t) {
      case TxType.sale:
        return 'Худалдан авалт';
      case TxType.purchase:
        return 'Татан авалт';
      case TxType.walletDeposit:
        return 'Хэтэвч цэнэглэлт';
      case TxType.walletWithdraw:
        return 'Зарлага';
      case TxType.unknown:
        return 'Бусад';
    }
  }
}
