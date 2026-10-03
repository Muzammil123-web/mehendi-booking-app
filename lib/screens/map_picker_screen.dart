import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String? address;
  PickedLocation(this.latitude, this.longitude, {this.address});
}

/// Blinkit/Zomato-style location picker: a pin is fixed in the center of
/// the screen, and the customer drags the MAP underneath it (instead of
/// tapping a precise point) — much easier to line up exactly with a house.
/// Includes an address search box (free OpenStreetMap Nominatim search,
/// no API key) so they can jump straight to their area first.
class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _defaultPosition = LatLng(20.5937, 78.9629); // center of India
  final MapController _mapController = MapController();
  final _searchCtrl = TextEditingController();
  LatLng _centerPosition = _defaultPosition;
  List<_SearchResult> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _centerPosition = widget.initialPosition ?? _defaultPosition;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5');
      final response =
          await http.get(uri, headers: {'User-Agent': 'MehendiStudioApp/1.0'});
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _searchResults = data
              .map((r) => _SearchResult(
                    displayName: r['display_name'],
                    lat: double.parse(r['lat']),
                    lon: double.parse(r['lon']),
                  ))
              .toList();
        });
      }
    } catch (_) {
      // Silently ignore — search is a convenience, not a requirement.
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _goTo(LatLng point) {
    _mapController.move(point, 16);
    setState(() {
      _centerPosition = point;
      _searchResults = [];
      _searchCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerPosition,
              initialZoom: widget.initialPosition != null ? 16 : 4.5,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _centerPosition = position.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mehendi_booking_app',
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

          // Fixed pin in the exact center of the screen — the map moves
          // underneath it, so whatever's under the pin tip is the pick.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40), // lift so the tip points at true center
                child: Icon(Icons.location_pin, size: 48, color: AppColors.primary),
              ),
            ),
          ),

          // Top bar: back button + search box
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search area, street, or landmark',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                      ),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final r = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, size: 18),
                            title: Text(r.displayName,
                                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                            onTap: () => _goTo(LatLng(r.lat, r.lon)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom confirm bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context)
                    .pop(PickedLocation(_centerPosition.latitude, _centerPosition.longitude)),
                child: const Text('Confirm This Location',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String displayName;
  final double lat;
  final double lon;
  _SearchResult({required this.displayName, required this.lat, required this.lon});
}
