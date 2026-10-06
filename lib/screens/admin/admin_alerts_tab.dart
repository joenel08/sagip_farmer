// ============================================================
// lib/screens/admin/admin_alerts_tab.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_widgets.dart';

class AdminAlertsTab extends StatefulWidget {
  const AdminAlertsTab({super.key});

  @override
  State<AdminAlertsTab> createState() => _AdminAlertsTabState();
}

class _AdminAlertsTabState extends State<AdminAlertsTab> {
  List<AlertModel> _alerts = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final a = await ApiService.getAllAlerts();
    if (!mounted) return;
    setState(() {
      _alerts = a;
      _loading = false;
    });
  }

  List<AlertModel> get _filtered {
    if (_filter == 'all') return _alerts;
    return _alerts.where((a) => a.severity == _filter).toList();
  }

  Color _sevColor(String s) {
    switch (s) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.soft),
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.green700),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.green700,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      _buildHero(),
                      const SizedBox(height: 16),
                      _buildFilters(),
                      const SizedBox(height: 12),
                      if (_filtered.isEmpty)
                        EmptyState(
                          icon: Icons.check_circle_outline,
                          title: _alerts.isEmpty
                              ? 'No alerts recorded'
                              : 'No $_filter alerts',
                          subtitle: _alerts.isEmpty
                              ? 'The system is running smoothly.'
                              : 'Try a different filter.',
                        )
                      else
                        ..._filtered.map(_alertCard),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Gradient hero header (matches dashboard) ───
  Widget _buildHero() {
    final high = _alerts.where((a) => a.severity == 'high').length;
    final medium = _alerts.where((a) => a.severity == 'medium').length;
    final low = _alerts.where((a) => a.severity == 'low').length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'System Alerts',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _heroStat('Total', '${_alerts.length}'),
              const SizedBox(width: 8),
              _heroStat('High', '$high', highlight: high > 0),
              const SizedBox(width: 8),
              _heroStat('Med', '$medium', highlight: medium > 0),
              const SizedBox(width: 8),
              _heroStat('Low', '$low'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: highlight
                ? AppColors.lime.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: highlight ? AppColors.lime : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['all', 'high', 'medium', 'low'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final active = _filter == f;
          final color = f == 'all' ? AppColors.green700 : _sevColor(f);

          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? color : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: active ? color : AppColors.line,
                ),
                boxShadow: active ? AppShadows.sm : null,
              ),
              child: Text(
                f == 'all' ? 'All' : f.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _alertCard(AlertModel a) {
    final c = _sevColor(a.severity);
    final hasOwner = a.userName.isNotEmpty;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Row 1: Severity icon + alert type + severity pill ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber_rounded, color: c, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.alertType,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(a.message, style: AppText.body),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: a.severity.toUpperCase(), color: c),
            ],
          ),

          // ─── Divider ───
          if (hasOwner) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
          ],

          // ─── Row 2: Owner info (name, address, contact) ───
          if (hasOwner) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with initials
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _initials(a.userName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Owner label
                      const Text(
                        'FARMER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (a.userContact.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 12, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              a.userContact,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (a.userAddress.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.green700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.userAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // ─── Row 3: Sensor + timestamp ───
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sensors,
                        size: 11, color: AppColors.green700),
                    const SizedBox(width: 4),
                    Text(
                      a.sensorName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, hh:mm a').format(a.createdAt),
                style: AppText.tiny,
              ),
            ],
          ),
        ],
      ),
    );
  }

// ─── Helper: get initials from a name ───
  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
