import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:location/location.dart' as loc;

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
  final loc.Location _location = loc.Location();

  bool _isPinDropped = false;

  Future<void> _getLatLngFromAddress(String address) async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _currentLocation = LatLng(locations.first.latitude, locations.first.longitude);
          _isPinDropped = true;
          _markers.clear();
          _markers.add(Marker(
            markerId: const MarkerId('address_marker'),
            position: _currentLocation,
            infoWindow: const InfoWindow(title: 'Selected Address'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));
        });

        _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
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
        setState(() {
          _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _isPinDropped = true;
          _markers.clear();
          _markers.add(Marker(
            markerId: const MarkerId('current_location_marker'),
            position: _currentLocation,
            infoWindow: const InfoWindow(title: 'Your Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));
        });

        _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
      } else {
        print("Permission Denied");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _onMapTapped(LatLng tappedPoint) {
    setState(() {
      _currentLocation = tappedPoint;
      _isPinDropped = true;
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('tapped_location_marker'),
        position: _currentLocation,
        infoWindow: const InfoWindow(title: 'Tapped Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    });

    _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
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
            child: SingleChildScrollView(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: _isPinDropped
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Pin your exact location',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Move the pin to your home for accurate delivery',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                                  Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Back Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF001F5B), // Text color
                  side: const BorderSide(color: Color(0xFF001F5B), width: 2), // Border color
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
                child: const Text('Back'),
              ),

              // Confirm Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F5B), // Dark blue
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  print("Location confirmed: $_currentLocation");
                },
                child: const Text('Confirm location'),
              ),
            ],
          ),

                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Enter your address',
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
                          const Text(
                            'Enter your address for more accurate location',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _getCurrentLocation,
                            child: const Text(
                              'Use my current location',
                              style: TextStyle(
                                color: Color(0xFF001F5B),
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
}
