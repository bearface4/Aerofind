import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class ConsumerSeeSellerLocationPage extends StatefulWidget {
  const ConsumerSeeSellerLocationPage({super.key});

  @override
  State<ConsumerSeeSellerLocationPage> createState() =>
      _ConsumerSeeSellerLocationPageState();
}

class _ConsumerSeeSellerLocationPageState
    extends State<ConsumerSeeSellerLocationPage> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(14.5547, 121.0194); // Default Manila
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String _address = '';
  String _storeName = '';
  bool _locationFound = false;
  int _geocodingAttempts = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    _address = args?['address'] ?? 'No address provided';
    _storeName = args?['storeName'] ?? 'Unknown Store';

    if (_address.isNotEmpty && _address != 'No address provided') {
      _geocodeAddress(_address);
    } else {
      setState(() {
        _isLoading = false;
        _addDefaultMarker();
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _addDefaultMarker() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('default_location'),
        position: _initialPosition,
        infoWindow: const InfoWindow(
          title: 'Location Unavailable',
          snippet: 'No address provided',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );
  }

  // Normalize address for better geocoding results
  String _normalizeAddress(String address) {
    String normalized = address.trim();

    // Add Philippines if not present
    if (!normalized.toLowerCase().contains('philippines') &&
        !normalized.toLowerCase().contains('ph')) {
      normalized = '$normalized, Philippines';
    }

    // Common abbreviation expansions
    normalized = normalized
        .replaceAll(RegExp(r'\bSt\b', caseSensitive: false), 'Street')
        .replaceAll(RegExp(r'\bAve\b', caseSensitive: false), 'Avenue')
        .replaceAll(RegExp(r'\bRd\b', caseSensitive: false), 'Road')
        .replaceAll(RegExp(r'\bBlvd\b', caseSensitive: false), 'Boulevard')
        .replaceAll(RegExp(r'\bBldg\b', caseSensitive: false), 'Building')
        .replaceAll(RegExp(r'\bBrgy\b', caseSensitive: false), 'Barangay');

    return normalized;
  }

  // Try multiple geocoding strategies
  Future<void> _geocodeAddress(String address) async {
    // Strategy 1: Try original address
    bool success = await _attemptGeocode(address);
    if (success) return;

    // Strategy 2: Try normalized address
    String normalized = _normalizeAddress(address);
    if (normalized != address) {
      debugPrint('[LOCATION_PAGE] Trying normalized address: "$normalized"');
      success = await _attemptGeocode(normalized);
      if (success) return;
    }

    // Strategy 3: Try extracting city/province and geocoding that
    String simplified = _simplifyAddress(address);
    if (simplified != address && simplified != normalized) {
      debugPrint('[LOCATION_PAGE] Trying simplified address: "$simplified"');
      success = await _attemptGeocode(simplified);
      if (success) return;
    }

    // Strategy 4: Try with just city name + Philippines
    String cityOnly = _extractCity(address);
    if (cityOnly.isNotEmpty) {
      debugPrint('[LOCATION_PAGE] Trying city only: "$cityOnly, Philippines"');
      success = await _attemptGeocode('$cityOnly, Philippines');
      if (success) return;
    }

    // All strategies failed
    setState(() {
      _locationFound = false;
      _isLoading = false;
      _addDefaultMarker();
    });
    _showErrorSnackBar(
      'Could not find exact location. Showing approximate area.',
    );
  }

  // Extract city from address (handles common Philippine address formats)
  String _extractCity(String address) {
    // Common Philippine cities
    final cities = [
      'Manila',
      'Quezon City',
      'Makati',
      'Pasig',
      'Taguig',
      'Pasay',
      'Mandaluyong',
      'Caloocan',
      'Marikina',
      'Valenzuela',
      'Las Piñas',
      'Parañaque',
      'Muntinlupa',
      'Malabon',
      'Navotas',
      'San Juan',
      'Cebu',
      'Davao',
      'Iloilo',
      'Bacolod',
      'Cagayan de Oro',
      'Baguio',
      'Angeles',
      'Antipolo',
      'Bacoor',
      'Cavite',
      'Laguna',
      'Batangas',
    ];

    for (String city in cities) {
      if (address.toLowerCase().contains(city.toLowerCase())) {
        return city;
      }
    }
    return '';
  }

  // Simplify address to major components
  String _simplifyAddress(String address) {
    // Remove unit/floor numbers, building names, and specific street numbers
    String simplified = address
        .replaceAll(RegExp(r'#\d+[A-Za-z]?'), '') // Remove unit numbers
        .replaceAll(RegExp(r'\d+th Floor'), '') // Remove floor info
        .replaceAll(RegExp(r'\d+nd Floor'), '')
        .replaceAll(RegExp(r'\d+st Floor'), '')
        .replaceAll(RegExp(r'\d+rd Floor'), '')
        .replaceAll(RegExp(r'Unit \d+'), '') // Remove unit info
        .replaceAll(RegExp(r'Lot \d+'), '') // Remove lot info
        .replaceAll(RegExp(r'Block \d+'), ''); // Remove block info

    // Keep only street, barangay, city, province
    return simplified.trim();
  }

  Future<bool> _attemptGeocode(String address) async {
    _geocodingAttempts++;
    try {
      debugPrint(
        '[LOCATION_PAGE] Geocoding attempt $_geocodingAttempts: "$address"',
      );

      List<geocoding.Location> locations = await geocoding
          .locationFromAddress(address)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[LOCATION_PAGE] Geocoding timeout');
              return [];
            },
          );

      if (locations.isNotEmpty) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);

        debugPrint(
          '[LOCATION_PAGE] ✓ Success! Coordinates: ${location.latitude}, ${location.longitude}',
        );

        setState(() {
          _initialPosition = newPosition;
          _locationFound = true;
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('store_location'),
              position: _initialPosition,
              infoWindow: InfoWindow(title: _storeName, snippet: _address),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
          _isLoading = false;
        });

        // Move camera to the pinned location with smooth animation
        if (_mapController != null) {
          await Future.delayed(const Duration(milliseconds: 300));
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              _initialPosition,
              _geocodingAttempts == 1
                  ? 17.0
                  : 15.0, // Closer zoom for exact address
            ),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[LOCATION_PAGE] Geocoding attempt failed: $e');
      return false;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    debugPrint('[LOCATION_PAGE] Google Map initialized');

    // Move camera to pinned store location if markers exist
    if (_markers.isNotEmpty && _locationFound) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_initialPosition, 17.0),
        );
      });
    }
  }

  // Zoom in button handler
  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  // Zoom out button handler
  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  // Re-center to store location
  void _recenterMap() {
    if (_mapController != null && _locationFound) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_initialPosition, 17.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store Location',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF002F6C),
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Finding location...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  Column(
                    children: [
                      // Store info card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _locationFound
                                      ? Icons.location_on
                                      : Icons.location_off,
                                  size: 24,
                                  color:
                                      _locationFound
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _storeName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: Text(
                                _address,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            if (!_locationFound)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 32,
                                  top: 4,
                                ),
                                child: Text(
                                  'Showing approximate location',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Google Map with pinned location
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: _initialPosition,
                              zoom: 17.0,
                            ),
                            markers: _markers,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: true,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            compassEnabled: true,
                            rotateGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            minMaxZoomPreference: const MinMaxZoomPreference(
                              10.0,
                              20.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Custom zoom and location controls
                  Positioned(
                    right: 32,
                    bottom: 100,
                    child: Column(
                      children: [
                        // Re-center button
                        if (_locationFound)
                          FloatingActionButton(
                            heroTag: 'recenter',
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: _recenterMap,
                            child: const Icon(
                              Icons.my_location,
                              color: Color(0xFF002F6C),
                            ),
                          ),
                        if (_locationFound) const SizedBox(height: 8),
                        // Zoom in button
                        FloatingActionButton(
                          heroTag: 'zoomIn',
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: _zoomIn,
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF002F6C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Zoom out button
                        FloatingActionButton(
                          heroTag: 'zoomOut',
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: _zoomOut,
                          child: const Icon(
                            Icons.remove,
                            color: Color(0xFF002F6C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
