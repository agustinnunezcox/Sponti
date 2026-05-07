import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/plan.dart';
import '../services/plan_service.dart';
import '../theme/app_theme.dart';
import 'plan_detail_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  GoogleMapController? _mapController;

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(20, 0),
    zoom: 2,
  );

  static const Map<String, LatLng> _cityCoords = {
    'Buenos Aires': LatLng(-34.6037, -58.3816),
    'Barcelona': LatLng(41.3851, 2.1734),
    'London': LatLng(51.5074, -0.1278),
    'New York': LatLng(40.7128, -74.0060),
    'Tokyo': LatLng(35.6762, 139.6503),
    'Paris': LatLng(48.8566, 2.3522),
    'Berlin': LatLng(52.5200, 13.4050),
    'Miami': LatLng(25.7617, -80.1918),
    'Mexico City': LatLng(19.4326, -99.1332),
    'São Paulo': LatLng(-23.5505, -46.6333),
    'Madrid': LatLng(40.4168, -3.7038),
    'Amsterdam': LatLng(52.3676, 4.9041),
    'Sydney': LatLng(-33.8688, 151.2093),
    'Dubai': LatLng(25.2048, 55.2708),
    'Rome': LatLng(41.9028, 12.4964),
  };

  bool get _mapsSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  LatLng? _coordsForPlan(Plan plan) {
    if (plan.lat != null && plan.lng != null) {
      return LatLng(plan.lat!, plan.lng!);
    }
    for (final entry in _cityCoords.entries) {
      if (plan.city.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(plan.city.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  Set<Marker> _buildMarkers(List<Plan> plans) {
    final markers = <Marker>{};
    // Track how many plans already placed at each coords to offset duplicates
    final seen = <String, int>{};

    for (final plan in plans) {
      final base = _coordsForPlan(plan);
      if (base == null) continue;

      final key = '${base.latitude},${base.longitude}';
      final idx = seen[key] ?? 0;
      seen[key] = idx + 1;

      // Spread plans in the same city by a small offset so markers don't stack
      final pos = LatLng(
        base.latitude + idx * 0.012,
        base.longitude + idx * 0.012,
      );

      markers.add(Marker(
        markerId: MarkerId(plan.id),
        position: pos,
        infoWindow: InfoWindow(
          title: plan.title,
          snippet: '${plan.city} · \$5 USD — toca para ver',
          onTap: () => _openDetail(plan),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    return markers;
  }

  void _openDetail(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapsSupported) {
      return const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 60, color: AppTheme.textSecondary),
              SizedBox(height: 16),
              Text('Mapa disponible en Android e iOS',
                  style: TextStyle(
                      fontSize: 16, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<Plan>>(
      stream: PlanService().getPlansForDate(date: DateTime.now()),
      builder: (context, snapshot) {
        final plans = snapshot.data ?? [];
        final markers = _buildMarkers(plans);

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _defaultCamera,
              markers: markers,
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 60,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded,
                        color: AppTheme.accent, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      plans.isEmpty
                          ? 'Cargando...'
                          : '${plans.length} planes hoy',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
