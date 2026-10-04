import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../services/location_service.dart';
import 'app_card.dart';

class NearbyBusinessRadar extends StatefulWidget {
  const NearbyBusinessRadar({super.key});

  @override
  State<NearbyBusinessRadar> createState() => _NearbyBusinessRadarState();
}

class _NearbyBusinessRadarState extends State<NearbyBusinessRadar> {
  final _mapController = MapController();
  Position? _position;
  List<Map<String, dynamic>> _businesses = [];
  bool _loading = true;
  String? _error;
  double _radiusKm = 25;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final position = await LocationService().determinePosition();
      final businesses = await LocationService().nearbyBusinesses(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _radiusKm,
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _businesses = businesses;
        _selectedId = businesses.firstOrNull?['user_id']?.toString();
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            13.5,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _select(Map<String, dynamic> business) {
    final lat = (business['latitude'] as num?)?.toDouble();
    final lon = (business['longitude'] as num?)?.toDouble();
    setState(() => _selectedId = business['user_id']?.toString());
    if (lat != null && lon != null) {
      _mapController.move(LatLng(lat, lon), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
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
                      'Local Radar',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _position == null
                          ? 'Use your location to discover nearby businesses.'
                          : '${_businesses.length} businesses within ${_radiusKm.round()} km',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _loading ? null : _scan,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.radar_rounded),
                tooltip: 'Scan nearby businesses',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 17,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                for (final radius in const [5.0, 10.0, 25.0, 50.0]) ...[
                  ChoiceChip(
                    label: Text('${radius.round()} km'),
                    selected: _radiusKm == radius,
                    onSelected: (selected) {
                      if (!selected || _loading) return;
                      setState(() => _radiusKm = radius);
                      _scan();
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(flex: 5, child: _buildMap()),
          const SizedBox(height: AppSpacing.md),
          Expanded(flex: 4, child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_position == null) {
      return AppCard(
        width: double.infinity,
        backgroundColor: AppColors.studentPrimary.withValues(alpha: 0.045),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.studentPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_searching_rounded,
                    color: AppColors.studentPrimary,
                    size: 30,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1800.ms),
            const SizedBox(height: AppSpacing.md),
            Text(
              _loading ? 'Finding your location…' : 'Location unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                  TextButton.icon(
                    onPressed: Geolocator.openAppSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('App settings'),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    final current = LatLng(_position!.latitude, _position!.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: current, initialZoom: 13.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.traxexco.launchpad',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: current,
                    radius: 90,
                    useRadiusInMeter: true,
                    color: AppColors.studentPrimary.withValues(alpha: 0.12),
                    borderColor: AppColors.studentPrimary.withValues(
                      alpha: 0.35,
                    ),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(markers: _markers(current)),
            ],
          ),
          Positioned(
            left: 10,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: FloatingActionButton.small(
              heroTag: 'radar-recenter',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.studentPrimary,
              onPressed: () => _mapController.move(current, 13.5),
              child: const Icon(Icons.my_location_rounded, size: 19),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).scale(begin: const Offset(0.98, 0.98));
  }

  List<Marker> _markers(LatLng current) => [
    Marker(
      point: current,
      width: 42,
      height: 42,
      child: const _CurrentMarker(),
    ),
    for (final business in _businesses)
      if (business['latitude'] is num && business['longitude'] is num)
        Marker(
          point: LatLng(
            (business['latitude'] as num).toDouble(),
            (business['longitude'] as num).toDouble(),
          ),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _select(business),
            child: _BusinessMarker(
              selected: business['user_id']?.toString() == _selectedId,
            ),
          ),
        ),
  ];

  Widget _buildList() {
    if (_loading && _businesses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_businesses.isEmpty) {
      return Center(
        child: Text(
          _position == null
              ? 'Nearby businesses will appear here.'
              : 'No businesses have published a location in this radius yet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.separated(
      itemCount: _businesses.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final business = _businesses[index];
        final distance = (business['distance_km'] as num?)?.toDouble();
        final selected = business['user_id']?.toString() == _selectedId;
        return AppCard(
          onTap: () => _select(business),
          backgroundColor: selected
              ? AppColors.businessPrimary.withValues(alpha: 0.07)
              : AppColors.surface,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.businessPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.businessPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business['business_name']?.toString() ?? 'Local Business',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [business['category'], business['address']]
                          .where(
                            (value) =>
                                value?.toString().trim().isNotEmpty == true,
                          )
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.studentPrimary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    distance < 1
                        ? '${(distance * 1000).round()} m'
                        : '${distance.toStringAsFixed(1)} km',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.studentPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 45).ms).slideX(begin: 0.04);
      },
    );
  }
}

class _CurrentMarker extends StatelessWidget {
  const _CurrentMarker();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.studentPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.studentPrimary.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
    ),
  );
}

class _BusinessMarker extends StatelessWidget {
  final bool selected;
  const _BusinessMarker({required this.selected});

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: selected ? 1.15 : 1,
    duration: AppDurations.fast,
    child: Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.businessPrimary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : AppColors.businessPrimary,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.businessPrimary.withValues(alpha: 0.28),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(
        Icons.storefront_rounded,
        size: 20,
        color: selected ? Colors.white : AppColors.businessPrimary,
      ),
    ),
  );
}
