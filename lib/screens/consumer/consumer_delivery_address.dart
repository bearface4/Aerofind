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
  final Set<Marker> _markers = {}; // For holding markers
  final TextEditingController _addressController = TextEditingController();
  final loc.Location _location = loc.Location(); // Create an instance of the Location package

  // Function to get latitude and longitude from the address
  Future<void> _getLatLngFromAddress(String address) async {
    try {
      // Convert address to lat/lng using Geocoding API (using geocoding.Location)
      List<geocoding.Location> locations = await geocoding.locationFromAddress(address); // Using geocoding's Location
      if (locations.isNotEmpty) {
        setState(() {
          _currentLocation = LatLng(locations.first.latitude, locations.first.longitude);
          // Remove old marker if exists
          _markers.clear();
          // Add a red marker at the new location
          _markers.add(Marker(
            markerId: MarkerId('address_marker'),
            position: _currentLocation,
            infoWindow: InfoWindow(title: 'Selected Address'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red Pin for all markers
          ));
        });

        // Move camera to the new position
        _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // Function to get the current location of the user
  Future<void> _getCurrentLocation() async {
    try {
      // Check if the app has permission to access the location
      var permissionStatus = await _location.requestPermission();
      if (permissionStatus == loc.PermissionStatus.granted) {
        // Get current location
        var currentLocation = await _location.getLocation();

        setState(() {
          _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          // Remove old marker if exists
          _markers.clear();
          // Add a red marker for current location
          _markers.add(Marker(
            markerId: MarkerId('current_location_marker'),
            position: _currentLocation,
            infoWindow: InfoWindow(title: 'Your Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red Pin for all markers
          ));
        });

        // Move camera to the current location
        _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
      } else {
        // Handle location permission denied
        print("Permission Denied");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // Function to handle tap on the map to drop a pin
  void _onMapTapped(LatLng tappedPoint) {
    setState(() {
      _currentLocation = tappedPoint;
      // Clear previous marker and add a new one at the tapped location
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId('tapped_location_marker'),
        position: _currentLocation,
        infoWindow: InfoWindow(title: 'Tapped Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red Pin for all markers
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
            markers: _markers, // Display the markers
            onTap: _onMapTapped, // Handle map taps to drop a pin
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
                height: 300, // Adjusted height for the bottom container
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30), // Curved only on the left side
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar for address input
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
                    // Image widget for the UI
                    Image.asset(
                      'assets/map.png', // Make sure to add the image in your assets folder
                      height: 120, // Adjust the height of the image as needed
                    ),
                    const SizedBox(height: 8), // Space between the image and the text
                    // Text for additional info
                    const Text(
                      'Enter your address for more accurate location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // "Use my current location" as clickable text
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
