// ============================================================
// lib/screens/user/plots_tab.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_widgets.dart';
import 'plot_form_screen.dart';

class PlotsTab extends StatefulWidget {
  final UserModel user;
  const PlotsTab({super.key, required this.user});

  @override
  State<PlotsTab> createState() => _PlotsTabState();
}

class _PlotsTabState extends State<PlotsTab> {
  List<Plot> _plots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await ApiService.getPlots(widget.user.id);
    if (!mounted) return;
    setState(() {
      _plots = p;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PlotFormScreen(user: widget.user)),
    );
    if (ok == true) _load();
  }

  Future<void> _delete(Plot p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Delete Sensor'),
        content: Text('Delete "${p.sensorName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deletePlot(p.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.soft),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green700,
                        ),
                      )
                    : _plots.isEmpty
                        ? EmptyState(
                            icon: Icons.sensors_off,
                            title: 'No sensors yet',
                            subtitle:
                                'Tap the button below to add your first sensor plot.',
                            action: PillButton(
                              label: 'ADD SENSOR',
                              icon: Icons.add,
                              gradient: AppGradients.accent,
                              textColor: AppColors.green950,
                              onPressed: _add,
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 120),
                            itemCount: _plots.length,
                            itemBuilder: (_, i) => _plotCard(_plots[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _plots.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: AppColors.green700,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Sensor',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Sensors', style: AppText.h1),
                const SizedBox(height: 4),
                Text(
                  _plots.isEmpty
                      ? 'No sensors registered'
                      : '${_plots.length} sensor${_plots.length == 1 ? "" : "s"} registered',
                  style: AppText.muted,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.sm,
            ),
            child: const Icon(Icons.grass, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _plotCard(Plot p) {
    final isWater = p.isWater;
    final color = isWater ? AppColors.info : AppColors.soil;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isWater ? Icons.water_drop : Icons.grass,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.sensorName,
                      style: AppText.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isWater ? 'Water Level Sensor' : 'Soil Moisture Sensor',
                      style: AppText.muted,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _delete(p),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
                tooltip: 'Delete',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _detailItem(
                  Icons.qr_code,
                  'Sensor ID',
                  p.sensorId,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _detailItem(
                  Icons.location_on_outlined,
                  'Location',
                  '${p.latitude.toStringAsFixed(3)}, ${p.longitude.toStringAsFixed(3)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.green700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.tiny),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}