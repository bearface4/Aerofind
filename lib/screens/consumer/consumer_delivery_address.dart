import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:location/location.dart' as loc;
import 'package:google_fonts/google_fonts.dart';

class ConsumerDeliveryAddress extends StatefulWidget {
  const ConsumerDeliveryAddress({super.key});

  @override
  _ConsumerDeliveryAddressState createState() => _ConsumerDeliveryAddressState();
}

class _ConsumerDeliveryAddressState extends State<ConsumerDeliveryAddress> {
  late GoogleMapController _mapController;
  LatLng _currentLocation = const LatLng(14.5547, 121.0194); // Default to Manila
  final Set<Marker> _markers = {};
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final loc.Location _location = loc.Location();

  bool _isPinDropped = false;
  bool _isLocationConfirmed = false;
  String _displayAddress = '';

  Future<void> _getLatLngFromAddress(String address) async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        LatLng newPosition = LatLng(locations.first.latitude, locations.first.longitude);
        _updateLocation(newPosition);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      var permissionStatus = await _location.requestPermission();
      if (permissionStatus == loc.PermissionStatus.granted) {
        var currentLocation = await _location.getLocation();
        LatLng newPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _updateLocation(newPosition);
      } else {
        print("Permission Denied");
      }
    } catch (e) {
      print("Error: $e");
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
      _markers.add(Marker(
        markerId: const MarkerId('location_marker'),
        position: _currentLocation,
        infoWindow: const InfoWindow(title: 'Selected Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    });

    _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
    await _getAddressFromLatLng(position);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _displayAddress =
              '${p.street}, ${p.locality}, ${p.subAdministrativeArea}, ${p.administrativeArea} ${p.postalCode}, ${p.country}';
        });
      }
    } catch (e) {
      print("Failed to get address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
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
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: _isPinDropped && !_isLocationConfirmed
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pin your exact location',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
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
                                    foregroundColor: const Color(0xFF001F5B),
                                    side: const BorderSide(color: Color(0xFF001F5B), width: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                  child: Text('Back', style: GoogleFonts.inter()),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF001F5B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isLocationConfirmed = true;
                                    });
                                  },
                                  child: Text('Confirm location', style: GoogleFonts.inter()),
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
                                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(0, -14),
                                      child: const Icon(Icons.location_on_outlined, size: 38),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                labelText: 'Floor/Unit/Room #',
                                labelStyle: GoogleFonts.inter(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF001F5B), width: 2),
                                ),
                              ),
                            ),

                                const SizedBox(height: 16),
                                Text(
                                  'Add Label',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLabelButton(Icons.home, "Home"),
                                    const SizedBox(width: 12),
                                    _buildLabelButton(Icons.work, "Work"),
                                    const SizedBox(width: 12),
                                    _buildLabelButton(Icons.favorite, "Partner"),
                                    const SizedBox(width: 12),
                                    _buildLabelButton(Icons.add, "Add"),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF001F5B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  onPressed: () {
                                    print("Address confirmed: $_displayAddress");
                                  },
                                  child: Text('Add location', style: GoogleFonts.inter()),
                                )
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
                                          _getLatLngFromAddress(_addressController.text);
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  'assets/map.png',
                                  height: 120,
                                ),
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
                                      color: const Color(0xFF001F5B),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLabelButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF001F5B)),
          ),
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12)),
      ],
    );
  }
}
