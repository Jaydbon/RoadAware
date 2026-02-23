import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  final LatLng? currentPosition;
  final List<LatLng> routePoints;
  final List<LatLng> brakePoints;
  final bool isRecording;

  const MapWidget({
    super.key,
    required this.currentPosition,
    required this.routePoints,
    required this.brakePoints,
    required this.isRecording,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != null &&
        widget.currentPosition != oldWidget.currentPosition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
            widget.currentPosition!,
            _mapController.camera.zoom,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = widget.currentPosition ?? const LatLng(51.5, -0.09);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
          onMapReady: () {
            if (widget.currentPosition != null) {
              _mapController.move(widget.currentPosition!, 15);
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
            'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=hyjNg0StqpggSG6ZeRBZ',
            userAgentPackageName: 'com.yourcompany.drivingapp',
            retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('MapTiler'),
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
          if (widget.routePoints.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.routePoints,
                  strokeWidth: 4.0,
                  color: Colors.blue,
                ),
              ],
            ),
          if (widget.routePoints.isNotEmpty)
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.routePoints.first,
                  width: 24,
                  height: 24,
                  child: const Icon(Icons.circle, color: Colors.green, size: 18),
                ),
              ],
            ),
          if (widget.brakePoints.isNotEmpty)
            MarkerLayer(
              markers: widget.brakePoints
                  .map((point) => Marker(
                point: point,
                width: 32,
                height: 32,
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 28),
              ))
                  .toList(),
            ),
          if (widget.currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.currentPosition!,
                  width: 40,
                  height: 40,
                  child: _CurrentLocationMarker(isRecording: widget.isRecording),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  final bool isRecording;
  const _CurrentLocationMarker({required this.isRecording});

  @override
  Widget build(BuildContext context) {
    final Color color = isRecording ? Colors.red : Colors.blue;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}