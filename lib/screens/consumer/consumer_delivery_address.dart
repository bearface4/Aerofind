import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:location/location.dart' as loc;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ConsumerDeliveryAddress extends StatefulWidget {
  const ConsumerDeliveryAddress({super.key});

  @override
  _ConsumerDeliveryAddressState createState() =>
      _ConsumerDeliveryAddressState();
}

class _ConsumerDeliveryAddressState extends State<ConsumerDeliveryAddress> {
  late GoogleMapController _mapController;
  LatLng _currentLocation = const LatLng(
    14.5547,
    121.0194,
  ); // Default to Manila
  final Set<Marker> _markers = {};
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final loc.Location _location = loc.Location();

  bool _isPinDropped = false;
  bool _isLocationConfirmed = false;
  String _displayAddress = '';

  // Label selection (Home, Work, Partner, or custom from “Add”)
  String? _selectedLabel;

  // API submit state + token
  bool _isSubmitting = false;
  String? _token;

  static const Color _brandBlue = Color(0xFF001F5B);

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('access_token');
    setState(() => _token = t);
    print('[ADDR] Loaded access_token? ${t != null && t.isNotEmpty}');
  }

  Future<void> _getLatLngFromAddress(String address) async {
    try {
      print('[ADDR] Geocoding from address input: "$address"');
      List<geocoding.Location> locations = await geocoding.locationFromAddress(
        address,
      );
      if (locations.isNotEmpty) {
        LatLng newPosition = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
        _updateLocation(newPosition);
      } else {
        print('[ADDR] Geocoding returned 0 results.');
      }
    } catch (e) {
      print("[ADDR] Geocoding error: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        final enabled = await _location.requestService();
        if (!enabled) {
          print('[ADDR] Location services disabled by user.');
          return;
        }
      }

      var permissionStatus = await _location.requestPermission();
      if (permissionStatus == loc.PermissionStatus.granted ||
          permissionStatus == loc.PermissionStatus.grantedLimited) {
        var currentLocation = await _location.getLocation();
        LatLng newPosition = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
        _updateLocation(newPosition);
      } else {
        print("[ADDR] Location permission denied");
      }
    } catch (e) {
      print("[ADDR] Current location error: $e");
    }
  }

  void _onMapTapped(LatLng tappedPoint) {
    _updateLocation(tappedPoint);
  }

  Future<void> _updateLocation(LatLng position) async {
    setState(() {
      _currentLocation = position;
      _isPinDropped = true;
      _isLocationConfirmed = false;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('location_marker'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });

    _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
    await _getAddressFromLatLng(position);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      print(
        '[ADDR] Reverse geocoding for ${position.latitude}, ${position.longitude}',
      );
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addr =
            '${p.street}, ${p.locality}, ${p.subAdministrativeArea}, ${p.administrativeArea} ${p.postalCode}, ${p.country}';
        print('[ADDR] Resolved address_line: $addr');
        setState(() {
          _displayAddress = addr;
        });
      } else {
        print('[ADDR] Reverse geocoding returned 0 placemarks.');
      }
    } catch (e) {
      print("[ADDR] Reverse geocoding failed: $e");
    }
  }

  Future<void> _handleAddCustomLabel() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Add custom label',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g., Parents, Condo, Dorm',
              hintStyle: GoogleFonts.inter(),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _brandBlue),
              onPressed: () {
                final text = controller.text.trim();
                Navigator.pop(context, text.isEmpty ? null : text);
              },
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    if (result != null) {
      print('[ADDR] Custom label selected: $result');
      setState(() {
        _selectedLabel = result;
      });
    }
  }

  Future<void> _submitAddress() async {
    if (_isSubmitting) return;

    final label = (_selectedLabel ?? '').trim(); // require non-empty
    final addressLine = _displayAddress;
    final barangay = _floorController.text.trim(); // optional
    const city = 'Manila'; // fixed value per requirement
    const isDefault = false; // use as-is per requirement

    if (_token == null || _token!.isEmpty) {
      print('[ADDR][ERROR] Missing access token — cannot submit.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // NEW: require label
    if (label.isEmpty) {
      print('[ADDR][WARN] label empty — ask user to select.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a label.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Already had: require display address
    if (addressLine.isEmpty) {
      print(
        '[ADDR][WARN] address_line empty — user must confirm location first.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm a location first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://aerofind-api.onrender.com/customer/addresses',
    );
    final payload = {
      'label': label,
      'address_line': addressLine,
      'barangay': barangay,
      'city': city,
      'is_default': isDefault,
    };

    print('[ADDR][POST] $url');
    print(
      '[ADDR][POST] Headers: {Content-Type: application/json, Authorization: Bearer ***}',
    );
    print('[ADDR][POST] Body: ${jsonEncode(payload)}');

    setState(() => _isSubmitting = true);
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token', // Bearer from SharedPreferences
        },
        body: jsonEncode(payload),
      );

      print('[ADDR][RESP] Status: ${resp.statusCode}');
      print('[ADDR][RESP] Raw: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final parsed = jsonDecode(resp.body);
          print('[ADDR][RESP][JSON] $parsed');
        } catch (_) {
          print('[ADDR][RESP][JSON] (non-JSON or empty body)');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address added!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // success: go back to previous screen
      } else if (resp.statusCode == 401) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add address (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('[ADDR][ERROR] POST failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while adding address.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _markers,
              onTap: _onMapTapped,
            ),
          ),
          Positioned(
            top: 30,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                bottomPadding > 0 ? bottomPadding : 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child:
                    _isPinDropped && !_isLocationConfirmed
                        ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pin your exact location',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Move the pin to your home for accurate delivery',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _brandBlue,
                                    side: const BorderSide(
                                      color: _brandBlue,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPinDropped = false;
                                      _markers.clear();
                                    });
                                  },
                                  child: Text(
                                    'Back',
                                    style: GoogleFonts.inter(),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isLocationConfirmed = true;
                                    });
                                  },
                                  child: Text(
                                    'Confirm location',
                                    style: GoogleFonts.inter(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                        : _isLocationConfirmed
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a new address',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -14),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayAddress.isNotEmpty
                                            ? _displayAddress
                                            : 'Loading address...',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('', style: GoogleFonts.inter()),
                                    ],
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -10),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isPinDropped = false;
                                        _isLocationConfirmed = false;
                                        _markers.clear();
                                        _floorController.clear();
                                        _addressController.clear();
                                        _displayAddress = '';
                                        _selectedLabel = null;
                                      });
                                    },
                                    child: const Icon(Icons.edit, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _floorController,
                              decoration: InputDecoration(
                                labelText: 'Floor/Unit/Room # (optional)',
                                labelStyle: GoogleFonts.inter(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: _brandBlue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Add Label',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLabelButton(
                                  Icons.home,
                                  "Home",
                                  selected: _selectedLabel == "Home",
                                  onTap:
                                      () => setState(
                                        () => _selectedLabel = "Home",
                                      ),
                                ),
                                const SizedBox(width: 12),
                                _buildLabelButton(
                                  Icons.work,
                                  "Work",
                                  selected: _selectedLabel == "Work",
                                  onTap:
                                      () => setState(
                                        () => _selectedLabel = "Work",
                                      ),
                                ),
                                const SizedBox(width: 12),
                                _buildLabelButton(
                                  Icons.favorite,
                                  "Partner",
                                  selected: _selectedLabel == "Partner",
                                  onTap:
                                      () => setState(
                                        () => _selectedLabel = "Partner",
                                      ),
                                ),
                                const SizedBox(width: 12),
                                _buildLabelButton(
                                  Icons.add,
                                  "Add",
                                  selected:
                                      _selectedLabel != null &&
                                      _selectedLabel != "Home" &&
                                      _selectedLabel != "Work" &&
                                      _selectedLabel != "Partner",
                                  onTap: _handleAddCustomLabel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedLabel != null &&
                                _selectedLabel != "Home" &&
                                _selectedLabel != "Work" &&
                                _selectedLabel != "Partner")
                              Center(
                                child: Text(
                                  'Label: $_selectedLabel',
                                  style: GoogleFonts.inter(
                                    color: _brandBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: _isSubmitting ? null : _submitAddress,
                              child: Text(
                                _isSubmitting ? 'Adding...' : 'Add location',
                                style: GoogleFonts.inter(),
                              ),
                            ),
                          ],
                        )
                        : Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: TextField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: 'Enter your address',
                                  labelStyle: GoogleFonts.inter(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      _getLatLngFromAddress(
                                        _addressController.text,
                                      );
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            Image.asset('assets/map.png', height: 120),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your address for more accurate location',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _getCurrentLocation,
                              child: Text(
                                'Use my current location',
                                style: GoogleFonts.inter(
                                  color: _brandBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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

  /// Label chip builder — fills dark blue when selected.
  Widget _buildLabelButton(
    IconData icon,
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  selected
                      ? _brandBlue
                      : Colors.transparent, // filled when selected
              border: Border.all(color: _brandBlue, width: 1.6),
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : Colors.black, // contrast on fill
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? _brandBlue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

//delivery address alt
