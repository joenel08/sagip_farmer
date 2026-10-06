// ============================================================
// lib/screens/user/dashboard_tab.dart
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_widgets.dart';
import 'plot_form_screen.dart';

class DashboardTab extends StatefulWidget {
  final UserModel user;
  const DashboardTab({super.key, required this.user});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<Plot> _plots = [];
  Plot? _selected;
  List<Reading> _readings = [];
  List<AlertModel> _alerts = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshData(),
    );
  }

  Future<void> _loadAll({int? preferId}) async {
    setState(() => _loading = true);

    final plots = await ApiService.getPlots(widget.user.id);
    final alerts = await ApiService.getAlerts(widget.user.id);
    if (!mounted) return;

    Plot? next;
    if (plots.isNotEmpty) {
      if (preferId != null) {
        next = plots.firstWhere((p) => p.id == preferId,
            orElse: () => plots.first);
      } else {
        next = plots.firstWhere((p) => p.id == _selected?.id,
            orElse: () => plots.first);
      }
    }

    setState(() {
      _plots = plots;
      _alerts = alerts;
      _selected = next;
      _loading = false;
    });
    if (_selected != null) await _refreshData();
  }

  Future<void> _refreshData() async {
    if (_selected == null) return;
    final res = await ApiService.getReadings(_selected!.id, limit: 20);
    final alerts = await ApiService.getAlerts(widget.user.id);
    if (!mounted) return;
    setState(() {
      _readings = (res['readings'] as List<Reading>?) ?? <Reading>[];
      _alerts = alerts;
    });
  }

  // ============================================================
  // STATUS HELPERS
  // ------------------------------------------------------------
  //  WATER LEVEL (reading = distance from sensor to water surface)
  //    >= 70 cm     -> LOW     (bad, water far away)
  //    31 – 69 cm   -> OPTIMAL
  //    <= 30 cm     -> HIGH    (flood risk, water close)
  //
  //  SOIL MOISTURE (ADC, capacitive sensor, higher = drier)
  //    >= 2784 ADC  -> DRY     (bad, needs water)
  //    961 – 2783   -> OPTIMAL
  //    <= 960 ADC   -> WET     (too much water)
  // ============================================================
  bool get _isWater => _selected?.sensorType == 'water_level';
  double get _latest => _readings.isNotEmpty ? _readings.last.value : 0;

  String _statusText(double v) {
    if (_isWater) {
      if (v >= 70) return 'LOW';       // 70 – 100+ cm
      if (v <= 30) return 'HIGH';      // 0 – 30 cm
      return 'OPTIMAL';                // 31 – 69 cm
    }
    if (v >= 2784) return 'DRY';       // 2784 – 4095 ADC
    if (v <= 960)  return 'WET';       // 0 – 960 ADC
    return 'OPTIMAL';                  // 961 – 2783 ADC
  }

  Color _statusColor(double v) {
    if (_isWater) {
      if (v >= 70) return AppColors.danger;
      if (v <= 30) return AppColors.warning;
      return AppColors.green600;
    }
    if (v >= 2784) return AppColors.danger;
    if (v <= 960)  return AppColors.info;
    return AppColors.soil;
  }

  Future<void> _addPlot() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PlotFormScreen(user: widget.user)),
    );
    if (added != true) return;

    final fresh = await ApiService.getPlots(widget.user.id);
    if (!mounted) return;
    if (fresh.isEmpty) {
      await _loadAll();
      return;
    }
    final newest = fresh.first;
    await _loadAll(preferId: newest.id);
    if (!mounted) return;
    setState(() => _selected = newest);
    await _refreshData();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.green700),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.soft),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.green700,
            onRefresh: _refreshData,
            child: _plots.isEmpty ? _buildEmpty() : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        _buildHeader(),
        const SizedBox(height: 60),
        EmptyState(
          icon: Icons.sensors_off,
          title: 'No sensors yet',
          subtitle:
              'Add your first sensor to start monitoring water level and soil moisture.',
          action: PillButton(
            label: 'ADD FIRST SENSOR',
            icon: Icons.add,
            gradient: AppGradients.accent,
            textColor: AppColors.green950,
            onPressed: _addPlot,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildSensorSelector(),
        const SizedBox(height: 20),
        _buildHeroCard(),
        const SizedBox(height: 20),
        _buildChartCard(),
        const SizedBox(height: 20),
        _buildAlertsCard(),
      ],
    );
  }

  // ─── Header with gradient hero ───
  Widget _buildHeader() {
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
                    Text(
                      'Hello, ${widget.user.fullName.split(' ').first}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Farm Overview',
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
                  Icons.agriculture,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _headerStat('Sensors', '${_plots.length}'),
              const SizedBox(width: 12),
              _headerStat(
                'Alerts',
                '${_alerts.length}',
                highlight: _alerts.isNotEmpty,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, {bool highlight = false}) {
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

  // ─── Sensor selector ───
  Widget _buildSensorSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<Plot>(
        value: _selected,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.green700),
        decoration: InputDecoration(
          labelText: 'Active sensor',
          prefixIcon: const Icon(Icons.sensors),
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.line),
          ),
        ),
        items: _plots
            .map((p) => DropdownMenuItem<Plot>(
                  value: p,
                  child: Text(
                    '${p.sensorName}  •  ${p.isWater ? "Water" : "Soil"}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ))
            .toList(),
        onChanged: (p) async {
          if (p == null) return;
          setState(() {
            _selected = p;
            _readings = [];
          });
          await _refreshData();
        },
      ),
    );
  }

  // ─── Hero reading card ───
  Widget _buildHeroCard() {
    final v = _latest;
    final isWater = _isWater;
    final color = _statusColor(v);
    final gradient = isWater ? AppGradients.water : AppGradients.soil;

    // Human-readable value + unit
    final valueText = isWater
        ? v.toStringAsFixed(1)     // e.g. "45.0"
        : v.toStringAsFixed(0);    // e.g. "2340"
    final unitText = isWater ? 'cm' : 'ADC';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header row ───
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isWater ? Icons.water_drop : Icons.grass,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWater ? 'Water Level' : 'Soil Moisture',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selected?.sensorName ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _statusText(v),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ─── Big value + unit ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valueText,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  unitText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Progress bar ───
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: isWater
                  ? (v / 100).clamp(0, 1)      // 0..100 cm scale
                  : (v / 4095).clamp(0, 1),   // 0..4095 ADC scale
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 12),

          // ─── Scale labels ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: (isWater
                    ? const ['0 cm', '50 cm', '100 cm']
                    : const ['0 ADC', '2048', '4095'])
                .map((l) => Text(
                      l,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── Chart card ───
  Widget _buildChartCard() {
    if (_readings.isEmpty) {
      return SoftCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.show_chart, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('No readings yet',
                style: AppText.h3, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Waiting for the first sensor reading…',
                style: AppText.muted, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final color = _statusColor(_latest);
    final spots = <FlSpot>[
      for (int i = 0; i < _readings.length; i++)
        FlSpot(i.toDouble(), _readings[i].value),
    ];

    // ─── Adaptive Y axis ───
    double maxY;
    double interval;
    if (_isWater) {
      final peak = _readings
          .map((r) => r.value)
          .fold<double>(0, (a, b) => a > b ? a : b);
      maxY = (peak * 1.2).clamp(20, 150).ceilToDouble();
      interval = (maxY / 4).ceilToDouble();
    } else {
      maxY = 4095;
      interval = 1024;
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Reading Trend',
            subtitle: _isWater
                ? 'Water level (cm)'
                : 'Soil moisture (ADC value)',
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.line,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: interval,
                      getTitlesWidget: (v, _) => Text(
                        _isWater
                            ? '${v.toInt()}cm'
                            : v.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: (_readings.length / 4)
                          .clamp(1, 100)
                          .toDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _readings.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('HH:mm')
                                .format(_readings[i].time),
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.ink,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              _isWater
                                  ? '${s.y.toStringAsFixed(1)} cm'
                                  : '${s.y.toStringAsFixed(0)} ADC',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.35),
                          color.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Alerts card ───
  Widget _buildAlertsCard() {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Alerts',
            subtitle: _alerts.isEmpty
                ? 'All clear'
                : '${_alerts.length} recent event${_alerts.length == 1 ? "" : "s"}',
            trailing: _alerts.isEmpty
                ? null
                : StatusPill(
                    label: '${_alerts.length}',
                    color: AppColors.danger,
                  ),
          ),
          const SizedBox(height: 16),
          if (_alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.green100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.green700,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('All good!', style: AppText.h3),
                    const SizedBox(height: 4),
                    Text('No alerts from your sensors.',
                        style: AppText.muted, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ..._alerts.take(6).map(_alertTile),
        ],
      ),
    );
  }

  Widget _alertTile(AlertModel a) {
    final c = a.severity == 'high'
        ? AppColors.danger
        : a.severity == 'medium'
            ? AppColors.warning
            : AppColors.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: c, size: 18),
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
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(a.message, style: AppText.body),
                const SizedBox(height: 6),
                Text(
                  DateFormat('MMM d, y • hh:mm a').format(a.createdAt),
                  style: AppText.tiny,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}