import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aerofind/routes/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;

  String _firstK(String s, int k) {
    if (s.length <= k) return s;
    return s.substring(0, k) + '...';
  }

  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController deliveryFeeController = TextEditingController();

  String storeType = 'Snacks';
  String profileImage = 'assets/placeholder.png';
  String bannerImage = 'assets/placeholder.png';

  // Original values for change detection
  String originalStoreName = '';
  String originalAddress = '';
  String originalStoreType = '';
  String originalDeliveryFee = '';

  final List<String> storeTypes = const [
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

  @override
  void dispose() {
    storeNameController.dispose();
    addressController.dispose();
    emailController.dispose();
    deliveryFeeController.dispose();
    super.dispose();
  }

  bool _isNetworkUrl(String? s) {
    if (s == null) return false;
    final v = s.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
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

        // Normalize delivery_fee
        final feeVal = data['delivery_fee'];
        String normalizedFee;
        if (feeVal == null) {
          normalizedFee = '0';
        } else if (feeVal is num) {
          normalizedFee = feeVal.toString();
        } else {
          normalizedFee = feeVal.toString();
        }

        setState(() {
          storeNameController.text = data['store_name']?.toString() ?? '';
          addressController.text = data['address']?.toString() ?? '';
          emailController.text = data['email']?.toString() ?? '';
          deliveryFeeController.text = normalizedFee;

          final apiStoreType = data['store_type']?.toString();
          storeType =
              storeTypes.contains(apiStoreType) ? apiStoreType! : 'Snacks';

          profileImage =
              (data['profile_image_url']?.toString().isNotEmpty ?? false)
                  ? data['profile_image_url'].toString()
                  : 'assets/placeholder.png';
          bannerImage =
              (data['banner_image_url']?.toString().isNotEmpty ?? false)
                  ? data['banner_image_url'].toString()
                  : 'assets/placeholder.png';

          // Save originals
          originalStoreName = storeNameController.text;
          originalAddress = addressController.text;
          originalStoreType = storeType;
          originalDeliveryFee = deliveryFeeController.text;
        });
      } else if (response.statusCode == 401) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      } else {
        debugPrint(
          'Failed to fetch profile: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  bool _sameFee(String a, String b) {
    final da = double.tryParse(a.replaceAll(',', '')) ?? 0.0;
    final db = double.tryParse(b.replaceAll(',', '')) ?? 0.0;
    return (da - db).abs() < 0.01;
  }

  Future<void> updateProfile() async {
    // Validate fee
    final feeStr = deliveryFeeController.text.trim();
    final parsedFee = double.tryParse(feeStr.replaceAll(',', ''));
    if (parsedFee == null || parsedFee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid delivery fee.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for changes
    final noChanges =
        storeNameController.text == originalStoreName &&
        addressController.text == originalAddress &&
        storeType == originalStoreType &&
        _sameFee(feeStr, originalDeliveryFee);

    if (noChanges) {
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
        "delivery_fee": parsedFee, // send fee from controller
        "latitude": 0,
        "longitude": 0,
      };

      final response = await http.put(
        Uri.parse('https://aerofind-api.onrender.com/seller/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => isEditing = false);
        await fetchProfile(); // refresh and reset originals
      } else if (response.statusCode == 401) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      } else {
        debugPrint(
          'Failed to update profile: ${response.statusCode} ${response.body}',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => isSaving = false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  // ---------------- Profile image picker and upload ----------------
  Future<void> _pickAndUploadProfileImage() async {
    if (profileImage != 'assets/placeholder.png')
      return; // Disable image selection when profile image is not null

    if (isEditing) return; // Disable image selection when in edit mode

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    // Upload to server
    final uri = Uri.parse(
      'https://aerofind-api.onrender.com/storage/upload/seller-profile-image',
    );

    // Create the multipart request with the correct field name 'image'
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            await http.MultipartFile.fromPath(
              'image',
              image.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          ); // Assuming the image is in JPEG format, change if needed.

    // Send the request
    final response = await request.send();
    final resp = await http.Response.fromStream(response);

    if (resp.statusCode == 200) {
      setState(() {
        profileImage = image.path; // Update profile image path
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await fetchProfile(); // Refresh the profile after upload
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload profile image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------- Banner image picker and upload ----------------
  Future<void> _pickAndUploadBannerImage() async {
    if (bannerImage != 'assets/placeholder.png')
      return; // Disable image selection when banner image is not null

    if (isEditing) return; // Disable image selection when in edit mode

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    // Upload to server
    final uri = Uri.parse(
      'https://aerofind-api.onrender.com/storage/upload/seller-banner',
    );

    // Create the multipart request with the correct field name 'image'
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            await http.MultipartFile.fromPath(
              'image',
              image.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          ); // Assuming the image is in JPEG format, change if needed.

    // Send the request
    final response = await request.send();
    final resp = await http.Response.fromStream(response);

    if (resp.statusCode == 200) {
      setState(() {
        bannerImage = image.path; // Update banner image path
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner image uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await fetchProfile(); // Refresh the profile after upload
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload banner image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------- Profile image delete ----------------
  Future<void> _deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    // Delete the profile image
    final uri = Uri.parse(
      'https://aerofind-api.onrender.com/storage/delete/seller-profile-image',
    );

    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        profileImage =
            'assets/placeholder.png'; // Reset to placeholder on delete
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await fetchProfile(); // Refresh the profile after deletion
    } else {
      debugPrint('Error deleting profile image: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete profile image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------- Banner image delete ----------------
  Future<void> _deleteBannerImage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    // Delete the banner image
    final uri = Uri.parse(
      'https://aerofind-api.onrender.com/storage/delete/seller-banner',
    );

    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        bannerImage =
            'assets/placeholder.png'; // Reset to placeholder on delete
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner image deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await fetchProfile(); // Refresh the profile after deletion
    } else {
      debugPrint('Error deleting banner image: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete banner image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerWidget =
        _isNetworkUrl(bannerImage)
            ? Image.network(
              bannerImage,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Image.asset(
                    'assets/placeholder.png',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
            )
            : Image.asset(
              bannerImage,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            );

    final ImageProvider avatarProvider =
        _isNetworkUrl(profileImage)
            ? NetworkImage(profileImage)
            : FileImage(
              File(profileImage),
            ); // Handle both network and file images.

    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      body: RefreshIndicator(
        onRefresh: fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap:
                        isEditing
                            ? null
                            : _pickAndUploadBannerImage, // Disable image picker in edit mode
                    child: bannerWidget,
                  ),
                  Positioned(
                    bottom: -50,
                    child: GestureDetector(
                      onTap:
                          isEditing
                              ? null
                              : _pickAndUploadProfileImage, // Disable image picker in edit mode
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            profileImage == 'assets/placeholder.png'
                                ? AssetImage('assets/placeholder.png')
                                : avatarProvider,
                      ),
                    ),
                  ),
                  // Trash bin for deleting profile image (under the store type text)
                  if (profileImage != 'assets/placeholder.png' && isEditing)
                    Positioned(
                      top: 150, // Placed under the store type
                      left: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: _deleteProfileImage,
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ),
                  // Trash bin for deleting banner image (Bottom-right)
                  if (bannerImage != 'assets/placeholder.png' && isEditing)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: IconButton(
                        onPressed: _deleteBannerImage,
                        icon: const Icon(Icons.delete, color: Colors.red),
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

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                )
              else if (isEditing)
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
                      _buildNumberField(
                        'Delivery Fee (₱)',
                        deliveryFeeController,
                      ),
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

  Widget _buildNumberField(String label, TextEditingController controller) {
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
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
