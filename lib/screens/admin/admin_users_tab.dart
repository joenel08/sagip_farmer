// ============================================================
// lib/screens/admin/admin_users_tab.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_widgets.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final u = await ApiService.getAdminUsers();
    if (!mounted) return;
    setState(() {
      _users = u;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final username = (u['username'] ?? '').toString().toLowerCase();
      final contact = (u['contact_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || username.contains(q) || contact.contains(q);
    }).toList();
  }

  // Total sensor count across all users
  int get _totalSensors {
    int n = 0;
    for (final u in _users) {
      n += ((u['plots'] as List?) ?? []).length;
    }
    return n;
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
                      const SizedBox(height: 20),
                      _buildSearch(),
                      const SizedBox(height: 20),
                      if (_filtered.isEmpty)
                        EmptyState(
                          icon: Icons.people_outline,
                          title: _users.isEmpty
                              ? 'No users yet'
                              : 'No matches',
                          subtitle: _users.isEmpty
                              ? 'No farmers have registered yet.'
                              : 'Try a different search term.',
                        )
                      else
                        ..._filtered.map(_userCard),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Gradient hero header (matches dashboard) ───
  Widget _buildHero() {
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
                      'Users & Sensors',
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
                  Icons.people_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _heroStat('Users', '${_users.length}'),
              const SizedBox(width: 12),
              _heroStat('Sensors', '$_totalSensors'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: highlight
                ? AppColors.lime.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: highlight ? AppColors.lime : Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (v) => setState(() => _search = v.trim()),
      decoration: InputDecoration(
        hintText: 'Search by name, username, or contact…',
        prefixIcon: const Icon(Icons.search),
        fillColor: AppColors.white,
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _search = ''),
              ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final plots = (u['plots'] as List?) ?? [];

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _initials(u['full_name']?.toString() ?? '?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          title: Text(
            u['full_name']?.toString() ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alternate_email,
                        size: 12, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      u['username']?.toString() ?? '',
                      style: AppText.tiny.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone,
                        size: 12, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      u['contact_number']?.toString() ?? '',
                      style: AppText.tiny.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: StatusPill(
            label: '${plots.length} sensor${plots.length == 1 ? "" : "s"}',
            color: AppColors.green700,
          ),
          children: [
            if (plots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors_off,
                        size: 18, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Text(
                      'No sensors registered',
                      style: AppText.muted
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            else
              ...plots.map<Widget>((p) => _plotRow(p)),
          ],
        ),
      ),
    );
  }

  Widget _plotRow(Map<String, dynamic> p) {
    final isWater = p['sensor_type'] == 'water_level';
    final color = isWater ? AppColors.info : AppColors.soil;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isWater ? Icons.water_drop : Icons.grass,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['sensor_name']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text('ID: ${p['sensor_id']}', style: AppText.tiny),
              ],
            ),
          ),
          Text(
            isWater ? 'Water' : 'Soil',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}