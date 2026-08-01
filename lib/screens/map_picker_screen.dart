import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  PickedLocation(this.latitude, this.longitude);
}

/// A full-screen map the customer can pan/zoom and tap anywhere to drop a
/// pin — used so a booking or order can be placed for a location other than
/// the customer's own current position (e.g. booking mehendi for a friend
/// at a different address). Uses OpenStreetMap — free, no API key needed.
class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _defaultPosition = LatLng(20.5937, 78.9629); // center of India
  LatLng? _pickedPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _pickedPosition = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          TextButton(
            onPressed: _pickedPosition == null
                ? null
                : () => Navigator.of(context).pop(
                    PickedLocation(_pickedPosition!.latitude, _pickedPosition!.longitude)),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition ?? _defaultPosition,
              initialZoom: widget.initialPosition != null ? 15 : 4.5,
              onTap: (tapPosition, point) => setState(() => _pickedPosition = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mehendi_booking_app',
              ),
              if (_pickedPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, size: 40, color: AppColors.primary),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pickedPosition == null
                          ? 'Tap anywhere on the map to drop a pin'
                          : 'Pin placed — tap Confirm above, or tap elsewhere to move it',
                      style: const TextStyle(fontSize: 13),
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
}
