import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/medicine.dart';
import '../models/paginated.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class MedicineFilter {
  const MedicineFilter({
    this.q,
    this.category,
    this.atcCode,
    this.minPrice,
    this.maxPrice,
    this.inStock = false,
    this.rx,
    this.hasInsurance = false,
  });

  final String? q;
  final String? category;
  final String? atcCode;
  final double? minPrice;
  final double? maxPrice;
  final bool inStock;
  final bool? rx; // null = бүгд, true = Rx, false = OTC
  final bool hasInsurance;

  int get activeCount {
    int n = 0;
    if (category != null) n++;
    if (atcCode != null) n++;
    if (minPrice != null) n++;
    if (maxPrice != null) n++;
    if (inStock) n++;
    if (rx != null) n++;
    if (hasInsurance) n++;
    return n;
  }

  MedicineFilter copyWith({
    Object? q = _sentinel,
    Object? category = _sentinel,
    Object? atcCode = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    bool? inStock,
    Object? rx = _sentinel,
    bool? hasInsurance,
  }) {
    return MedicineFilter(
      q: q == _sentinel ? this.q : q as String?,
      category: category == _sentinel ? this.category : category as String?,
      atcCode: atcCode == _sentinel ? this.atcCode : atcCode as String?,
      minPrice: minPrice == _sentinel ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
      inStock: inStock ?? this.inStock,
      rx: rx == _sentinel ? this.rx : rx as bool?,
      hasInsurance: hasInsurance ?? this.hasInsurance,
    );
  }
}

const _sentinel = Object();

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  MedicineFilter _filter = const MedicineFilter();
  late Future<PaginatedMedicines> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {}); // for clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _filter = _filter.copyWith(q: _search.text.trim().isEmpty ? null : _search.text.trim());
      _refresh();
    });
  }

  Future<PaginatedMedicines> _load() {
    final state = context.read<AppState>();
    return state.medicines.allPaginated(
      q: _filter.q,
      category: _filter.category,
      atcCode: _filter.atcCode,
      minPrice: _filter.minPrice,
      maxPrice: _filter.maxPrice,
      inStock: _filter.inStock ? true : null,
      prescriptionRequired: _filter.rx,
      hasInsurance: _filter.hasInsurance ? true : null,
      size: 100,
    );
  }

  void _refresh() => setState(() => _future = _load());

  void _openFilters() async {
    final result = await showModalBottomSheet<MedicineFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (result != null) {
      _filter = result;
      _refresh();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _search.text.isNotEmpty;
    final activeFilters = _filter.activeCount;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Нэр, INN, ATC, баркод...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: hasText
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _search.clear();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FilterButton(active: activeFilters, onTap: _openFilters),
            ],
          ),
        ),
        if (activeFilters > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _ActiveFilterRow(
              filter: _filter,
              onClear: () {
                _filter = const MedicineFilter();
                _refresh();
              },
            ),
          ),
        Expanded(
          child: FutureBuilder<PaginatedMedicines>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _ErrorView(error: snap.error, onRetry: _refresh);
              }
              final list = snap.data?.items ?? const [];
              if (list.isEmpty) {
                return const _EmptyView(
                  icon: Icons.medication_outlined,
                  message: 'Эм олдсонгүй',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _MedicineCard(medicine: list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});
  final int active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active > 0 ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: active > 0 ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.tune,
                  size: 22,
                  color: active > 0
                      ? Colors.white
                      : AppColors.textSecondary),
              if (active > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                        minWidth: 16, minHeight: 16),
                    child: Text(
                      '$active',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
}

class _ActiveFilterRow extends StatelessWidget {
  const _ActiveFilterRow({required this.filter, required this.onClear});
  final MedicineFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    void chip(String label) {
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark)),
      ));
    }

    if (filter.category != null) chip('Ангилал: ${filter.category}');
    if (filter.atcCode != null) chip('ATC: ${filter.atcCode}');
    if (filter.minPrice != null) chip('≥ ${filter.minPrice!.toInt()}₮');
    if (filter.maxPrice != null) chip('≤ ${filter.maxPrice!.toInt()}₮');
    if (filter.inStock) chip('Нөөцтэй');
    if (filter.rx == true) chip('Жортой');
    if (filter.rx == false) chip('Жоргүй');
    if (filter.hasInsurance) chip('Даатгалтай');

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...chips,
        InkWell(
          onTap: onClear,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text('Цэвэрлэх ✕',
                style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final MedicineFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _category = widget.initial.category;
  late String? _atcCode = widget.initial.atcCode;
  late final TextEditingController _minCtrl = TextEditingController(
      text: widget.initial.minPrice?.toInt().toString() ?? '');
  late final TextEditingController _maxCtrl = TextEditingController(
      text: widget.initial.maxPrice?.toInt().toString() ?? '');
  late bool _inStock = widget.initial.inStock;
  late bool? _rx = widget.initial.rx;
  late bool _hasInsurance = widget.initial.hasInsurance;

  static const _categories = [
    'Анальгетик',
    'Антибиотик',
    'Зүрх судас',
    'Амьсгалын',
    'Мэдрэл',
    'Витамин',
    'Ходоодны',
    'Арьс',
    'Нүд/Чих',
  ];

  static const _atcGroups = [
    ('A', 'Хоол боловсруулах'),
    ('B', 'Цус'),
    ('C', 'Зүрх судас'),
    ('D', 'Арьс'),
    ('J', 'Антибиотик / халдвар'),
    ('M', 'Үе мөч'),
    ('N', 'Мэдрэл'),
    ('R', 'Амьсгалын'),
  ];

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minCtrl.text.trim());
    final max = double.tryParse(_maxCtrl.text.trim());
    Navigator.of(context).pop(MedicineFilter(
      q: widget.initial.q,
      category: _category,
      atcCode: _atcCode,
      minPrice: min,
      maxPrice: max,
      inStock: _inStock,
      rx: _rx,
      hasInsurance: _hasInsurance,
    ));
  }

  void _reset() {
    setState(() {
      _category = null;
      _atcCode = null;
      _minCtrl.clear();
      _maxCtrl.clear();
      _inStock = false;
      _rx = null;
      _hasInsurance = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Шүүлтүүр',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 14),

              const _SectionLabel('Ангилал'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SelectChip(
                    label: 'Бүгд',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final c in _categories)
                    _SelectChip(
                      label: c,
                      selected: _category == c,
                      onTap: () =>
                          setState(() => _category = _category == c ? null : c),
                    ),
                ],
              ),

              const SizedBox(height: 14),
              const _SectionLabel('ATC ангилал'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SelectChip(
                    label: 'Бүгд',
                    selected: _atcCode == null,
                    onTap: () => setState(() => _atcCode = null),
                  ),
                  for (final g in _atcGroups)
                    _SelectChip(
                      label: '${g.$1} · ${g.$2}',
                      selected: _atcCode == g.$1,
                      onTap: () => setState(
                          () => _atcCode = _atcCode == g.$1 ? null : g.$1),
                    ),
                ],
              ),

              const SizedBox(height: 14),
              const _SectionLabel('Үнийн хязгаар (₮)'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Доод',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Дээд',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const _SectionLabel('Жор'),
              Wrap(
                spacing: 6,
                children: [
                  _SelectChip(
                    label: 'Бүгд',
                    selected: _rx == null,
                    onTap: () => setState(() => _rx = null),
                  ),
                  _SelectChip(
                    label: 'Жоргүй',
                    selected: _rx == false,
                    onTap: () =>
                        setState(() => _rx = _rx == false ? null : false),
                  ),
                  _SelectChip(
                    label: 'Жортой',
                    selected: _rx == true,
                    onTap: () =>
                        setState(() => _rx = _rx == true ? null : true),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Зөвхөн нөөцтэй эм',
                    style: TextStyle(fontSize: 14)),
                value: _inStock,
                onChanged: (v) => setState(() => _inStock = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Зөвхөн даатгалтай (хөнгөлөлттэй)',
                    style: TextStyle(fontSize: 14)),
                value: _hasInsurance,
                onChanged: (v) => setState(() => _hasInsurance = v),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Цэвэрлэх'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _apply,
                      child: const Text('Хэрэглэх'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary)),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.borderSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              )),
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final m = medicine;
    final outOfStock = m.quantity <= 0;
    final hasInsurance = m.hasInsuranceDiscount;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _MedicineDetailsDialog(medicine: m),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.medication,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (m.prescriptionRequired) ...[
                          const SizedBox(width: 6),
                          const _Badge(label: 'Rx', color: AppColors.warning),
                        ],
                        if (hasInsurance) ...[
                          const SizedBox(width: 4),
                          _Badge(
                              label: '−${m.insuranceDiscountPercent}%',
                              color: AppColors.info),
                        ],
                      ],
                    ),
                    if (m.innName != null || m.atcCode != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (m.innName != null) m.innName,
                          if (m.atcCode != null) m.atcCode,
                        ].whereType<String>().join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (hasInsurance) ...[
                          Text(
                            formatCurrency(m.price),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              formatCurrency(m.discountedPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ] else
                          Flexible(
                            child: Text(
                              formatCurrency(m.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: outOfStock
                                ? AppColors.danger.withValues(alpha: 0.1)
                                : AppColors.borderSoft,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            outOfStock ? 'Дууссан' : '${m.quantity}ш',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: outOfStock
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AddButton(
                enabled: !outOfStock,
                onTap: () async {
                  try {
                    await context.read<AppState>().addToCart(m.barcode);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${m.name} нэмэгдлээ'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Алдаа: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : AppColors.borderSoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.add,
            color: enabled ? Colors.white : AppColors.textMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MedicineDetailsDialog extends StatelessWidget {
  const _MedicineDetailsDialog({required this.medicine});
  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final m = medicine;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: Text(
                      m.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('Баркод', m.barcode),
                      if (m.innName != null) _detailRow('INN', m.innName!),
                      if (m.atcCode != null) _detailRow('ATC', m.atcCode!),
                      if (m.form != null) _detailRow('Хэлбэр', m.form!),
                      if (m.manufacturer != null)
                        _detailRow('Үйлдвэрлэгч', m.manufacturer!),
                      if (m.category != null)
                        _detailRow('Ангилал', m.category!),
                      _detailRow('Үнэ', formatCurrency(m.price)),
                      if (m.hasInsuranceDiscount) ...[
                        _detailRow('Даатгалын хөнгөлөлт',
                            '−${m.insuranceDiscountPercent}%'),
                        _detailRow('Та төлөх дүн',
                            formatCurrency(m.discountedPrice)),
                      ],
                      _detailRow('Үлдэгдэл', '${m.quantity} ширхэг'),
                      if (m.expiryDate != null)
                        _detailRow('Дуусах', dateFmt.format(m.expiryDate!)),
                      _detailRow(
                          'Жор',
                          m.prescriptionRequired
                              ? 'Шаардлагатай'
                              : 'Шаардлагагүй'),
                      if (m.description != null) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          m.description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Хаах'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error is ApiException
        ? (error as ApiException).message
        : 'Холболтын алдаа';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Дахин оролдох'),
            ),
          ],
        ),
      ),
    );
  }
}
