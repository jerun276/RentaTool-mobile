import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../catalog/models/equipment_model.dart';
import '../../catalog/services/catalog_service.dart';
import '../services/location_service.dart';

class BookingMapScreen extends ConsumerStatefulWidget {
  const BookingMapScreen({super.key});

  @override
  ConsumerState<BookingMapScreen> createState() => _BookingMapScreenState();
}

class _BookingMapScreenState extends ConsumerState<BookingMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  double _radiusKm = 15.0; // Default 15km search radius
  bool _isLoading = true;
  List<EquipmentModel> _equipmentList = [];
  EquipmentModel? _selectedEquipment;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _initializeLocationAndEquipment();
  }

  Future<void> _initializeLocationAndEquipment() async {
    setState(() => _isLoading = true);

    try {
      final locService = ref.read(locationServiceProvider);
      final catalogService = ref.read(catalogServiceProvider);

      // 1. Get GPS coordinates
      final position = await locService.getCurrentPosition();
      _currentPosition = position ??
          Position(
            latitude: LocationService.defaultLatitude,
            longitude: LocationService.defaultLongitude,
            timestamp: DateTime.now(),
            accuracy: 50.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );

      // 2. Fetch catalog equipment
      final items = await catalogService.getEquipment();
      _equipmentList = items;

      _updateMapOverlays();
    } catch (e) {
      debugPrint('Error loading map data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateMapOverlays() {
    if (_currentPosition == null) return;

    final userLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    // 1. Draw search radius circle
    final circle = Circle(
      circleId: const CircleId('search_radius'),
      center: userLatLng,
      radius: _radiusKm * 1000.0, // Convert km to meters
      fillColor: AppColors.primary.withOpacity(0.12),
      strokeColor: AppColors.primaryLight,
      strokeWidth: 2,
    );

    // 2. Place Markers for equipment within radius
    final markers = <Marker>{};

    // User location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location (Renter)'),
      ),
    );

    final locService = ref.read(locationServiceProvider);

    for (int i = 0; i < _equipmentList.length; i++) {
      final eq = _equipmentList[i];

      // Assign deterministic coordinates spread around user position if backend doesn't provide GPS
      final offsetLat = ((i % 5) - 2) * 0.035;
      final offsetLng = (((i ~/ 5) % 5) - 2) * 0.035;
      final eqLat = _currentPosition!.latitude + offsetLat;
      final eqLng = _currentPosition!.longitude + offsetLng;

      final dist = locService.distanceInKm(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        eqLat,
        eqLng,
      );

      // Filter by radius
      if (dist <= _radiusKm) {
        markers.add(
          Marker(
            markerId: MarkerId(eq.id),
            position: LatLng(eqLat, eqLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              eq.isWearLocked ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueCyan,
            ),
            infoWindow: InfoWindow(
              title: eq.title,
              snippet: 'LKR ${eq.dailyRate.toInt()}/day • ${dist.toStringAsFixed(1)} km',
            ),
            onTap: () {
              setState(() {
                _selectedEquipment = eq;
              });
            },
          ),
        );
      }
    }

    setState(() {
      _circles = {circle};
      _markers = markers;
    });
  }

  void _onRadiusChanged(double newRadius) {
    setState(() {
      _radiusKm = newRadius;
      _updateMapOverlays();
    });

    if (_mapController != null && _currentPosition != null) {
      double zoomLevel = 13.0;
      if (_radiusKm >= 30) {
        zoomLevel = 10.5;
      } else if (_radiusKm >= 15) {
        zoomLevel = 11.8;
      } else if (_radiusKm >= 10) {
        zoomLevel = 12.5;
      }

      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoomLevel,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'LKR ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Map Radius Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Map & Location',
            onPressed: _initializeLocationAndEquipment,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Locating nearby machinery & equipment...')
          : Stack(
              children: [
                // 1. Google Map View
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? LocationService.defaultLatitude,
                      _currentPosition?.longitude ?? LocationService.defaultLongitude,
                    ),
                    zoom: 12.0,
                  ),
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (_) {
                    if (_selectedEquipment != null) {
                      setState(() => _selectedEquipment = null);
                    }
                  },
                ),

                // 2. Top Radius Filter Chips Bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.radar, color: AppColors.primaryLight, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Radius: ${_radiusKm.toInt()} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [5.0, 10.0, 15.0, 25.0].map((r) {
                            final isSel = _radiusKm == r;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text('${r.toInt()}km', style: const TextStyle(fontSize: 11)),
                                selected: isSel,
                                onSelected: (_) => _onRadiusChanged(r),
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Recenter Floating Button
                Positioned(
                  right: 16,
                  bottom: _selectedEquipment != null ? 220 : 24,
                  child: FloatingActionButton.small(
                    heroTag: 'map_recenter_fab',
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: AppColors.primaryLight,
                    onPressed: () {
                      if (_currentPosition != null && _mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            12.5,
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),

                // 4. Selected Equipment Preview Card
                if (_selectedEquipment != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
                      ),
                      color: AppColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedEquipment!.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => _selectedEquipment = null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedEquipment!.categoryName,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DAILY RATE',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      currencyFormatter.format(_selectedEquipment!.dailyRate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                AppButton(
                                  text: 'Reserve Equipment',
                                  icon: Icons.calendar_today,
                                  onPressed: () {
                                    context.push('/bookings/create', extra: _selectedEquipment);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
