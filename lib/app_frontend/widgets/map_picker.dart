// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class MapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final void Function(double latitude, double longitude, String address)
      onLocationSelected;

  const MapPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  // MapTiler style URL (MapLibre-compatible, free tier)
  // Get your free key from https://cloud.maptiler.com/ and replace YOUR_MAPTILER_KEY below
  static const String mapboxStyleUrl =
      'https://api.maptiler.com/maps/streets/style.json?key=JZupGWeUog3EDN1iSIii';

  // ignore: deprecated_member_use
  MaplibreMapController? mapController;
  double? latitude;
  double? longitude;
  String? address;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    latitude = widget.initialLatitude ?? 12.9716; // Default: Bangalore
    longitude = widget.initialLongitude ?? 77.5946;
    address = widget.initialAddress;
    if (address == null && latitude != null && longitude != null) {
      _reverseGeocode(latitude!, longitude!);
    }
    requestLocationPermission();
  }

  Future<void> _geocode(String query) async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/geocode_address/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'address': query}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          longitude = data['longitude'];
          latitude = data['latitude'];
        });
        mapController
            ?.moveCamera(CameraUpdate.newLatLng(LatLng(latitude!, longitude!)));
        _reverseGeocode(latitude!, longitude!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address not found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/reverse_geocode/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'latitude': lat, 'longitude': lon}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          address = data['address'];
        });
      } else {
        setState(() {
          address = null;
        });
      }
    } catch (e) {
      setState(() {
        address = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ignore: deprecated_member_use
  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
  }

  void _onMapTap(Point<double> point, LatLng latLng) {
    if (kDebugMode) {
      print('Map tapped at: ${latLng.latitude}, ${latLng.longitude}');
    }
    setState(() {
      latitude = latLng.latitude;
      longitude = latLng.longitude;
    });
    _reverseGeocode(latLng.latitude, latLng.longitude);
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permission is required to use the map.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for an address',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                if (_searchController.text.trim().isNotEmpty) {
                  _geocode(_searchController.text.trim());
                }
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _geocode(value.trim());
            }
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              // ignore: deprecated_member_use
              MaplibreMap(
                styleString: mapboxStyleUrl,
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude ?? 12.9716, longitude ?? 77.5946),
                  zoom: 14,
                ),
                onMapCreated: _onMapCreated,
                onMapClick: _onMapTap,
                myLocationEnabled: true,
                myLocationTrackingMode: MyLocationTrackingMode.tracking,
              ),
              if (latitude != null && longitude != null)
                const IgnorePointer(
                  child: Center(
                    child:
                        Icon(Icons.location_pin, size: 48, color: Colors.red),
                  ),
                ),
              if (isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          address != null
              ? 'Selected Address: $address'
              : 'No address selected',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Use this location'),
          onPressed: (latitude != null && longitude != null && address != null)
              ? () {
                  widget.onLocationSelected(latitude!, longitude!, address!);
                }
              : null,
        ),
      ],
    );
  }
}
