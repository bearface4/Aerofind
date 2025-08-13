import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aerofind/routes/app_routes.dart';

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;

  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String storeType = 'Snacks';
  String profileImage = 'assets/placeholder.png';
  String bannerImage = 'assets/placeholder.png';

  // Store original values to compare for changes
  String originalStoreName = '';
  String originalAddress = '';
  String originalStoreType = '';

  final List<String> storeTypes = [
    "Snacks",
    "Beverage",
    "Printing",
    "Clothing",
    "Health",
    "Beauty",
    "School Supplies",
    "General",
    "Aviation/Aeronautics",
  ];

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final response = await http.get(
        Uri.parse('https://aerofind-api.onrender.com/seller/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          storeNameController.text = data['store_name'] ?? '';
          addressController.text = data['address'] ?? '';
          emailController.text = data['email'] ?? '';
          storeType =
              storeTypes.contains(data['store_type'])
                  ? data['store_type']
                  : 'Snacks';
          profileImage =
              data['profile_image_url']?.isNotEmpty == true
                  ? data['profile_image_url']
                  : 'assets/placeholder.png';
          bannerImage =
              data['banner_image_url']?.isNotEmpty == true
                  ? data['banner_image_url']
                  : 'assets/placeholder.png';

          // Store original values for change detection
          originalStoreName = storeNameController.text;
          originalAddress = addressController.text;
          originalStoreType = storeType;
        });
      } else {
        debugPrint('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> updateProfile() async {
    // Check if there are any changes
    if (storeNameController.text == originalStoreName &&
        addressController.text == originalAddress &&
        storeType == originalStoreType) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save.'),
          backgroundColor: Colors.grey,
        ),
      );
      setState(() => isEditing = false);
      return;
    }

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final body = {
        "email": emailController.text,
        "password": "fixedpassword",
        "store_name": storeNameController.text,
        "store_type": storeType,
        "store_info": "placeholder info",
        "address": addressController.text,
        "delivery_fee": 0,
        "latitude": 0,
        "longitude": 0,
      };

      debugPrint('Updating profile with: $body');

      final response = await http.put(
        Uri.parse('https://aerofind-api.onrender.com/seller/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => isEditing = false);
        fetchProfile(); // Refresh data
      } else {
        debugPrint(
          'Failed to update profile: ${response.statusCode} ${response.body}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }

    setState(() => isSaving = false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token'); // Dispose token
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      body: RefreshIndicator(
        onRefresh: fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Banner and profile
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    bannerImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: -50,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(profileImage),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Text(
                storeNameController.text,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                storeType,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed:
                          isEditing
                              ? updateProfile
                              : () {
                                setState(() => isEditing = true);
                              },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff002366),
                        side: const BorderSide(color: Color(0xff002366)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child:
                          isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xff002366),
                                ),
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEditing ? Icons.save : Icons.edit,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isEditing ? 'Save' : 'Edit',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      _buildTextField('Store Name', storeNameController),
                      _buildDropdown(),
                      _buildTextField('Address', addressController),
                      _buildReadOnlyField('Email Address', emailController),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      _buildViewField('Address', addressController.text),
                      const Divider(thickness: 1),
                      _buildViewField('Contact Number', '0908234405'),
                      const Divider(thickness: 1),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: logout,
                          icon: const Icon(
                            Icons.logout,
                            color: Color(0xff002366),
                          ),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.inter(
                              color: const Color(0xff002366),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xff002366), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Store Type',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: storeType,
          items:
              storeTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() => storeType = value!);
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xff002366), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildViewField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
