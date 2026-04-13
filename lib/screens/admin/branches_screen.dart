import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/branch.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  late Future<List<Branch>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().branches.all();
  }

  void _reload() {
    setState(() => _future = context.read<AppState>().branches.all());
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final managerCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Шинэ салбар'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Нэр',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Хаяг',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Утас',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: managerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Эрхлэгч',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Болих'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Нэмэх'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      if (nameCtrl.text.trim().isEmpty) return;
      try {
        await context.read<AppState>().branches.create(
              name: nameCtrl.text.trim(),
              address: addressCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              managerName: managerCtrl.text.trim(),
            );
        _reload();
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      nameCtrl.dispose();
      addressCtrl.dispose();
      phoneCtrl.dispose();
      managerCtrl.dispose();
    }
  }

  Future<void> _delete(Branch b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Устгах уу?'),
        content: Text('${b.name} салбарыг устгахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болих'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<AppState>().branches.delete(b.id);
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<Branch>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Алдаа: ${snap.error}'));
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'Салбар байхгүй',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _BranchCard(branch: list[i], onDelete: () => _delete(list[i])),
        );
      },
    );

    final fab = FloatingActionButton.extended(
      onPressed: _showAddDialog,
      icon: const Icon(Icons.add),
      label: const Text('Шинэ салбар'),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Салбарууд')),
      floatingActionButton: fab,
      body: body,
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch, required this.onDelete});

  final Branch branch;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final b = branch;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.store_outlined,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (b.address != null && b.address!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            b.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (b.phone != null && b.phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          b.phone!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (b.managerName != null &&
                      b.managerName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            b.managerName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.textMuted, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
