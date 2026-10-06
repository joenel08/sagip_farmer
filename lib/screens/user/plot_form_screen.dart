// ============================================================
// lib/screens/user/plot_form_screen.dart
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

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
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  String _type = 'water_level';
  bool _saving = false;

  // ---------------- geocoding state ----------------
  final MapController _mapController = MapController();
  LatLng? _marker;
  bool _locating = false;
  bool _reverseLocating = false;
  bool _gettingLocation = false;  // ← NEW: "use my location" in progress
  String? _addressPreview;
  String? _geoError;

  Timer? _reverseDebounce;

  static const LatLng _defaultCenter = LatLng(12.8797, 121.7740);

  @override
  void initState() {
    super.initState();
    _lat.addListener(_syncMarkerFromFields);
    _lng.addListener(_syncMarkerFromFields);
  }

  void _syncMarkerFromFields() {
    final la = double.tryParse(_lat.text.trim());
    final lo = double.tryParse(_lng.text.trim());
    if (la == null || lo == null) return;
    if (la < -90 || la > 90 || lo < -180 || lo > 180) return;

    final newMarker = LatLng(la, lo);
    if (_marker == newMarker) return;

    setState(() => _marker = newMarker);
    _mapController.move(newMarker, 16);
  }

  // ============================================================
  // FORWARD GEOCODE — address -> lat/lng
  // ============================================================
  Future<void> _locateFromAddress() async {
    final query = _address.text.trim();
    if (query.isEmpty) {
      setState(() => _geoError = 'Enter an address first.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _locating = true;
      _geoError = null;
      _addressPreview = null;
    });

    final result = await GeocodingService.fromAddress(query);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _locating = false;
        _geoError = 'Address not found. Try adding city / province / country.';
      });
      return;
    }

    final pos = LatLng(result.latitude, result.longitude);

    setState(() {
      _locating = false;
      _marker = pos;
      _lat.text = result.latitude.toStringAsFixed(6);
      _lng.text = result.longitude.toStringAsFixed(6);
      _addressPreview = 'Found: ${result.displayName}';
    });

    _mapController.move(pos, 16);
  }

  // ============================================================
  // REVERSE GEOCODE — coordinates -> address
  // ============================================================
  Future<void> _reverseFromCoordinates(LatLng pos) async {
    setState(() {
      _reverseLocating = true;
      _geoError = null;
    });

    final result = await GeocodingService.fromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    if (!mounted) return;

    setState(() {
      _reverseLocating = false;
      if (result != null && result.displayName.isNotEmpty) {
        _address.text = result.displayName;
        _addressPreview = 'Address updated from map pin.';
      }
    });
  }

  // ============================================================
  // USE MY CURRENT LOCATION  ← NEW
  // ============================================================
  Future<void> _useCurrentLocation() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _gettingLocation = true;
      _geoError = null;
      _addressPreview = null;
    });

    try {
      final loc = await LocationService.getCurrentPosition();

      if (!mounted) return;

      final pos = LatLng(loc.latitude, loc.longitude);

      setState(() {
        _marker = pos;
        _lat.text = loc.latitude.toStringAsFixed(6);
        _lng.text = loc.longitude.toStringAsFixed(6);
        _gettingLocation = false;
        _addressPreview = 'Using your current location — updating address…';
      });

      _mapController.move(pos, 17);

      // Reverse-geocode to fill the address field
      await _reverseFromCoordinates(pos);

      if (!mounted) return;
      setState(() {
        _addressPreview = 'Location set to your current position.';
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _gettingLocation = false;
        _geoError = e.message;
      });

      // Offer to open OS settings for the two most common problems
      if (e.type == LocationError.serviceDisabled) {
        _showOpenSettingsDialog(
          title: 'Location is off',
          message: e.message,
          buttonLabel: 'Open Location Settings',
          onOpen: LocationService.openLocationSettings,
        );
      } else if (e.type == LocationError.permissionDeniedForever) {
        _showOpenSettingsDialog(
          title: 'Permission blocked',
          message: e.message,
          buttonLabel: 'Open App Settings',
          onOpen: LocationService.openAppSettings,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gettingLocation = false;
        _geoError = 'Could not get your location. Try again.';
      });
    }
  }

  void _showOpenSettingsDialog({
    required String title,
    required String message,
    required String buttonLabel,
    required Future<void> Function() onOpen,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onOpen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP TAP
  // ============================================================
  void _onMapTap(LatLng pos) {
    setState(() {
      _marker = pos;
      _lat.text = pos.latitude.toStringAsFixed(6);
      _lng.text = pos.longitude.toStringAsFixed(6);
      _addressPreview = null;
    });

    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 700), () {
      _reverseFromCoordinates(pos);
    });
  }

  // ============================================================
  // SAVE
  // ============================================================
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
          SnackBar(
            content: Text(res['message'] ?? 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot reach server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _mapController.dispose();
    _name.dispose();
    _sensorId.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isWater = _type == 'water_level';

    return Scaffold(
     appBar: AppBar(
    title: const Text('Add Sensor Plot'),
    flexibleSpace: Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
    ),
  ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------- preview icon --------
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (isWater
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF795548))
                        .withOpacity(.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWater ? Icons.water_drop : Icons.grass,
                    size: 48,
                    color: isWater
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF795548),
                  ),
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
                  DropdownMenuItem(
                      value: 'water_level', child: Text('Water Level')),
                  DropdownMenuItem(
                      value: 'soil_moisture', child: Text('Soil Moisture')),
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
              const SizedBox(height: 24),

              // ============================================================
              // LOCATION SECTION
              // ============================================================
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  const Text(
                    'Location',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // -------- address + locate button --------
              TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.words,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Full Address',
                  hintText:
                      'e.g., Purok 3, Brgy. Tangub, Bacolod City, Negros Occidental',
                  prefixIcon: const Icon(Icons.home_outlined),
                  alignLabelWithHint: true,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Find on map',
                            icon: const Icon(Icons.search,
                                color: Color(0xFF2E7D32)),
                            onPressed: _locateFromAddress,
                          ),
                  ),
                ),
              ),

              // ============================================================
              //  "USE MY CURRENT LOCATION" BUTTON   ← NEW
              // ============================================================
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _gettingLocation ? null : _useCurrentLocation,
                  icon: _gettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location,
                          color: Color(0xFF2E7D32)),
                  label: Text(
                    _gettingLocation
                        ? 'Getting your location…'
                        : 'Use my current location',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              if (_geoError != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _geoError!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],

              if (_addressPreview != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _addressPreview!,
                        style: const TextStyle(
                            color: Color(0xFF2E7D32), fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              if (_reverseLocating) ...[
                const SizedBox(height: 6),
                Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Updating address from pin…',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // -------- INTERACTIVE MAP --------
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 240,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _marker ?? _defaultCenter,
                          initialZoom: _marker != null ? 16 : 5.5,
                          onTap: (_, pos) => _onMapTap(pos),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.sagipfarmer',
                          ),
                          if (_marker != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _marker!,
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Color(0xFFC62828),
                                    size: 44,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Hint overlay
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap the map to place / move the pin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),

                      // GPS jump button inside map
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: IconButton(
                            tooltip: 'Center on my location',
                            icon: _gettingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.gps_fixed,
                                    color: Color(0xFF2E7D32),
                                  ),
                            onPressed:
                                _gettingLocation ? null : _useCurrentLocation,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // -------- lat / lng fields --------
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '14.5995',
                        prefixIcon: Icon(Icons.my_location),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        final d = double.tryParse(v.trim());
                        if (d == null || d < -90 || d > 90) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lng,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '120.9842',
                        prefixIcon: Icon(Icons.explore_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        final d = double.tryParse(v.trim());
                        if (d == null || d < -180 || d > 180) {
                          return 'Invalid';
                        }
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
                    const Icon(Icons.info_outline,
                        size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Type an address and tap 🔍 to auto-fill coordinates, '
                        'tap 📍 to use your current GPS location, '
                        'or tap the map to fine-tune the exact spot.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            height: 1.4),
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