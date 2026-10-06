// ============================================================
// lib/screens/user/plot_form_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class PlotFormScreen extends StatefulWidget {
  final UserModel user;
  const PlotFormScreen({super.key, required this.user});

  @override
  State<PlotFormScreen> createState() => _PlotFormScreenState();
}

class _PlotFormScreenState extends State<PlotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sensorId = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  String _type = 'water_level';
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final res = await ApiService.addPlot(
        userId: widget.user.id,
        sensorName: _name.text.trim(),
        sensorType: _type,
        sensorId: _sensorId.text.trim(),
        latitude: double.parse(_lat.text.trim()),
        longitude: double.parse(_lng.text.trim()),
      );

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sensor plot added successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot reach server.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sensorId.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWater = _type == 'water_level';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sensor Plot'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // -------- preview icon --------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (isWater ? const Color(0xFF1565C0) : const Color(0xFF795548))
                      .withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWater ? Icons.water_drop : Icons.grass,
                  size: 48,
                  color: isWater ? const Color(0xFF1565C0) : const Color(0xFF795548),
                ),
              ),
              const SizedBox(height: 24),

              // -------- sensor name --------
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Sensor Name',
                  hintText: 'e.g., Rice Field A',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter sensor name' : null,
              ),
              const SizedBox(height: 16),

              // -------- sensor type --------
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Sensor Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'water_level', child: Text('Water Level')),
                  DropdownMenuItem(value: 'soil_moisture', child: Text('Soil Moisture')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'water_level'),
              ),
              const SizedBox(height: 16),

              // -------- sensor id --------
              TextFormField(
                controller: _sensorId,
                decoration: const InputDecoration(
                  labelText: 'Sensor ID',
                  hintText: 'e.g., ESP32-A1B2',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter sensor ID' : null,
              ),
              const SizedBox(height: 16),

              // -------- coordinates --------
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '14.5995',
                        prefixIcon: Icon(Icons.my_location),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final d = double.tryParse(v.trim());
                        if (d == null || d < -90 || d > 90) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lng,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '120.9842',
                        prefixIcon: Icon(Icons.explore_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final d = double.tryParse(v.trim());
                        if (d == null || d < -180 || d > 180) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enter the GPS coordinates where the sensor is installed. '
                        'You can read them from Google Maps (right-click the location).',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'SAVING…' : 'SAVE SENSOR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
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