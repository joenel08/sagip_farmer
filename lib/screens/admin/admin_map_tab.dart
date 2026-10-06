// ============================================================
// lib/screens/admin/admin_map_tab.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_widgets.dart';

class AdminMapTab extends StatefulWidget {
  const AdminMapTab({super.key});

  @override
  State<AdminMapTab> createState() => _AdminMapTabState();
}

class _AdminMapTabState extends State<AdminMapTab> {
  List<Plot> _sensors = [];
  bool _loading = true;
  Plot? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await ApiService.getAdminSensors();
    if (!mounted) return;
    setState(() {
      _sensors = s;
      _loading = false;
    });
  }

  int get _waterCount => _sensors.where((s) => s.isWater).length;
  int get _soilCount => _sensors.where((s) => !s.isWater).length;

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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: _buildHero(),
                    ),
                    Expanded(
                      child: _sensors.isEmpty
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: EmptyState(
                                icon: Icons.map_outlined,
                                title: 'No sensors on the map',
                                subtitle:
                                    'Sensors added by farmers will appear here.',
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              child: _buildMap(),
                            ),
                    ),
                  ],
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
                      'Sensor Map',
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
                  Icons.map,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _heroStat('Total', '${_sensors.length}'),
              const SizedBox(width: 10),
              _heroStat('Water', '$_waterCount'),
              const SizedBox(width: 10),
              _heroStat('Soil', '$_soilCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: highlight
                ? AppColors.lime.withOpacity(0.4)
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

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                _sensors.first.latitude,
                _sensors.first.longitude,
              ),
              initialZoom: 11,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sagip_final',
              ),
              MarkerLayer(
                markers: _sensors.map((s) => _marker(s)).toList(),
              ),
            ],
          ),

          // Legend
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _LegendDot(color: AppColors.info, label: 'Water Level'),
                  SizedBox(height: 8),
                  _LegendDot(color: AppColors.soil, label: 'Soil Moisture'),
                ],
              ),
            ),
          ),

          // Selected info
          if (_selected != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _selectedInfo(_selected!),
            ),
        ],
      ),
    );
  }

  Marker _marker(Plot s) {
    final isWater = s.isWater;
    final color = isWater ? AppColors.info : AppColors.soil;
    final isSelected = _selected?.id == s.id;

    return Marker(
      point: LatLng(s.latitude, s.longitude),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => setState(() => _selected = s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.green700 : color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.green700 : color)
                    .withOpacity(0.4),
                blurRadius: isSelected ? 16 : 8,
                spreadRadius: isSelected ? 4 : 0,
              ),
            ],
          ),
          child: Icon(
            isWater ? Icons.water_drop : Icons.grass,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _selectedInfo(Plot s) {
    final isWater = s.isWater;
    final color = isWater ? AppColors.info : AppColors.soil;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isWater ? Icons.water_drop : Icons.grass,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.sensorName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.muted,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => setState(() => _selected = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _infoRow('Sensor ID', s.sensorId)),
              Expanded(
                child:
                    _infoRow('Type', isWater ? 'Water Level' : 'Soil'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _infoRow(
            'Coordinates',
            '${s.latitude.toStringAsFixed(5)}, ${s.longitude.toStringAsFixed(5)}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.tiny),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}