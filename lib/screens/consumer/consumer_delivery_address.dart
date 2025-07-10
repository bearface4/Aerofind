import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; 

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

  // Function to get latitude and longitude from the address
  Future<void> _getLatLngFromAddress(String address) async {
    try {
      // Convert address to lat/lng using Geocoding API
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _currentLocation = LatLng(locations.first.latitude, locations.first.longitude);
          // Add a marker at the location
          _markers.add(Marker(
            markerId: MarkerId('address_marker'),
            position: _currentLocation,
            infoWindow: InfoWindow(title: 'Selected Address'),
          ));
        });

        // Move camera to the new position
        _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Address'),
        backgroundColor: const Color(0xFF001F5B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
          ),
          Column(
            children: [
              // Text field for address input
              Container(
                margin: const EdgeInsets.all(16),
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
              // Button to use current location
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      // Implement logic to get the current location here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001F5B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Use my current location'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
