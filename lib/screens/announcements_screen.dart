import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/announcement.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<Announcement>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Announcement>> _load() {
    return context.read<AppState>().announcements.activeAnnouncements();
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Announcement>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final msg = snap.error is ApiException
              ? (snap.error as ApiException).message
              : 'Холболтын алдаа';
          return _ErrorState(message: msg, onRetry: _refresh);
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return const _EmptyState();
        }
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AnnouncementCard(item: list[i]),
          ),
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final meta = _typeMeta(item.type);
    return InkWell(
      onTap: () => _showDetails(context, item),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(meta.icon, color: meta.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(meta.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: meta.color,
                                letterSpacing: 0.3)),
                      ),
                      if (item.pinned) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.push_pin, size: 12, color: AppColors.textMuted),
                      ],
                      const Spacer(),
                      Text(_when(item.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      )),
                  const SizedBox(height: 4),
                  Text(item.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Announcement a) {
    final meta = _typeMeta(a.type);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(meta.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: meta.color)),
                ),
                const Spacer(),
                Text(_when(a.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 12),
            Text(a.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3)),
            const SizedBox(height: 10),
            Text(a.content,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.55)),
          ],
        ),
      ),
    );
  }
}

class _TypeMeta {
  const _TypeMeta(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

_TypeMeta _typeMeta(AnnouncementType t) {
  switch (t) {
    case AnnouncementType.promo:
      return _TypeMeta('ХӨНГӨЛӨЛТ', AppColors.success, Icons.local_offer_outlined);
    case AnnouncementType.alert:
      return _TypeMeta('АНХААРУУЛГА', AppColors.danger, Icons.warning_amber);
    case AnnouncementType.info:
      return _TypeMeta('МЭДЭЭЛЭЛ', AppColors.info, Icons.info_outline);
    case AnnouncementType.news:
      return _TypeMeta('ЗАР', AppColors.primary, Icons.campaign_outlined);
  }
}

String _when(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'дөнгөж сая';
  if (diff.inHours < 1) return '${diff.inMinutes} мин';
  if (diff.inDays < 1) return '${diff.inHours} цаг';
  if (diff.inDays < 7) return '${diff.inDays} өдөр';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            child: const Icon(Icons.campaign_outlined,
                size: 32, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          const Text('Одоогоор зар алга',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Дахин оролдох')),
          ],
        ),
      ),
    );
  }
}
