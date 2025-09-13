import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerofind/routes/app_routes.dart';

class Address {
  final int id;
  final String label;
  final String addressLine;
  final String barangay;
  final String city;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.barangay,
    required this.city,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      label: json['label'] ?? '',
      addressLine: json['address_line'] ?? '',
      barangay: json['barangay'] ?? '',
      city: json['city'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (addressLine.isNotEmpty && addressLine != 'N/A') parts.add(addressLine);
    if (barangay.isNotEmpty && barangay != 'N/A') parts.add(barangay);
    if (city.isNotEmpty && city != 'N/A') parts.add(city);
    return parts.isNotEmpty ? parts.join(', ') : 'No address on file';
  }
}

class ConsumerProfilePage extends StatefulWidget {
  const ConsumerProfilePage({super.key});

  @override
  State<ConsumerProfilePage> createState() => _ConsumerProfilePageState();
}

class _ConsumerProfilePageState extends State<ConsumerProfilePage> {
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingImage = false;
  bool isDeletingImage = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  late String originalFirstName;
  late String originalLastName;
  late String originalPhone;

  // Address related
  List<Address> addresses = [];
  Address? defaultAddress;

  // Profile picture related
  File? _selectedProfileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

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
        Uri.parse('https://aerofind-api.onrender.com/customer/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Profile data: $data");

        // Parse addresses
        if (data['addresses'] != null) {
          addresses =
              (data['addresses'] as List)
                  .map((addr) => Address.fromJson(addr))
                  .toList();

          // Find default address
          try {
            defaultAddress = addresses.firstWhere((addr) => addr.isDefault);
          } catch (e) {
            // If no default address found, use the first one if available
            defaultAddress = addresses.isNotEmpty ? addresses.first : null;
          }
        }

        setState(() {
          firstNameController.text = data['first_name'] ?? '';
          lastNameController.text = data['last_name'] ?? '';
          contactController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? '';

          // Set address controller with default address
          addressController.text =
              defaultAddress?.fullAddress ?? "No address on file";

          originalFirstName = firstNameController.text;
          originalLastName = lastNameController.text;
          originalPhone = contactController.text;
        });

        // Fetch profile picture after loading profile data
        await fetchProfilePicture();
      } else {
        debugPrint("Failed to fetch profile: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchProfilePicture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final response = await http.get(
        Uri.parse('https://aerofind-api.onrender.com/customer/profile/picture'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint("Profile picture fetch - Status: ${response.statusCode}");
      debugPrint("Profile picture fetch - Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['image_url'] != null &&
            data['image_url'].toString().trim().isNotEmpty) {
          setState(() {
            _profileImageUrl = data['image_url'];
          });
          debugPrint("Profile picture URL loaded: $_profileImageUrl");
        } else {
          debugPrint("No profile picture URL found in response");
        }
      } else if (response.statusCode == 404) {
        debugPrint("No profile picture found (404) - using placeholder");
        // This is normal if user hasn't uploaded a profile picture yet
        setState(() {
          _profileImageUrl = null;
        });
      } else {
        debugPrint("Failed to fetch profile picture: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching profile picture: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfileImage = File(pickedFile.path);
        });
        debugPrint("Image selected: ${pickedFile.path}");

        // Upload the selected image immediately
        await _uploadProfilePicture();
      } else {
        debugPrint("No image selected");
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting image from gallery'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedProfileImage == null) return;

    setState(() => isUploadingImage = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final uri = Uri.parse(
        'https://aerofind-api.onrender.com/customer/profile/picture',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Get the file path
      final filePath = _selectedProfileImage!.path;
      final fileName = path.basename(filePath);

      // Determine MIME type from file
      String? mimeType = lookupMimeType(filePath);

      debugPrint("File path: $filePath");
      debugPrint("File name: $fileName");
      debugPrint("Detected MIME type: $mimeType");

      // Create MultipartFile with correct content type
      http.MultipartFile multipartFile;

      if (mimeType != null) {
        // Split MIME type (e.g., "image/jpeg" -> ["image", "jpeg"])
        final mimeTypeData = mimeType.split('/');
        if (mimeTypeData.length == 2) {
          multipartFile = await http.MultipartFile.fromPath(
            'file', // This field name might need adjustment based on your API
            filePath,
            filename: fileName,
            contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
          );
          debugPrint(
            "Created MultipartFile with MIME type: ${mimeTypeData[0]}/${mimeTypeData[1]}",
          );
        } else {
          // Fallback if MIME type splitting fails
          multipartFile = await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: fileName,
          );
          debugPrint(
            "Created MultipartFile without specific MIME type (split failed)",
          );
        }
      } else {
        // Fallback for when MIME type detection fails
        // Assume it's an image based on common extensions
        final extension = path.extension(filePath).toLowerCase();
        MediaType? contentType;

        switch (extension) {
          case '.jpg':
          case '.jpeg':
            contentType = MediaType('image', 'jpeg');
            break;
          case '.png':
            contentType = MediaType('image', 'png');
            break;
          case '.gif':
            contentType = MediaType('image', 'gif');
            break;
          case '.webp':
            contentType = MediaType('image', 'webp');
            break;
          case '.bmp':
            contentType = MediaType('image', 'bmp');
            break;
          case '.tiff':
          case '.tif':
            contentType = MediaType('image', 'tiff');
            break;
          default:
            contentType = MediaType('image', 'jpeg'); // Default fallback
            break;
        }

        multipartFile = await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
          contentType: contentType,
        );
        debugPrint(
          "Created MultipartFile with fallback MIME type: ${contentType.mimeType}",
        );
      }

      // Add the file to the request
      request.files.add(multipartFile);

      debugPrint("Uploading profile picture...");
      debugPrint("Upload URL: $uri");
      debugPrint("Request headers: ${request.headers}");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint("Upload response status: ${response.statusCode}");
      debugPrint("Upload response body: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Profile picture uploaded successfully");

        // Parse response to get the new image URL if provided
        try {
          final data = jsonDecode(responseBody);
          if (data['image_url'] != null) {
            setState(() {
              _profileImageUrl = data['image_url'];
            });
          }
        } catch (e) {
          debugPrint("Could not parse upload response: $e");
        }

        // Refresh profile picture from server
        await fetchProfilePicture();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        debugPrint("Failed to upload profile picture: ${response.statusCode}");

        // Try to parse error message from response
        String errorMessage =
            'Failed to upload profile picture (${response.statusCode})';
        try {
          final errorData = jsonDecode(responseBody);
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          }
        } catch (e) {
          debugPrint("Could not parse error response: $e");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error uploading profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error uploading profile picture'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isUploadingImage = false);
  }

  Future<void> _deleteProfilePicture() async {
    setState(() => isDeletingImage = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final response = await http.delete(
        Uri.parse('https://aerofind-api.onrender.com/customer/profile/picture'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint("Delete profile picture - Status: ${response.statusCode}");
      debugPrint("Delete profile picture - Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("Profile picture deleted successfully");

        // Clear local state
        setState(() {
          _profileImageUrl = null;
          _selectedProfileImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 404) {
        debugPrint("No profile picture to delete (404)");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No profile picture to delete'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        debugPrint("Failed to delete profile picture: ${response.statusCode}");

        // Try to parse error message from response
        String errorMessage =
            'Failed to delete profile picture (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          }
        } catch (e) {
          debugPrint("Could not parse error response: $e");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error deleting profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting profile picture'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isDeletingImage = false);
  }

  void _onProfileAvatarTap() {
    if (isUploadingImage || isDeletingImage) return;

    if (isEditing &&
        (_profileImageUrl != null || _selectedProfileImage != null)) {
      // Show delete confirmation dialog when in edit mode and there's a profile picture
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Profile Picture'),
              content: const Text(
                'Are you sure you want to delete your profile picture?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteProfilePicture();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );
    } else {
      // Pick image when not in edit mode or no profile picture exists
      _pickImageFromGallery();
    }
  }

  Future<void> updateProfile() async {
    // Validate phone before sending
    final phone = contactController.text.trim();
    if (phone.length != 11 || !phone.startsWith('09')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone must start with 09 and be 11 digits long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final body = {
        "first_name": firstNameController.text,
        "last_name": lastNameController.text,
        "middle_name": null,
        "suffix": null,
        "phone": phone,
      };

      debugPrint("Updating profile with: $body");

      final response = await http.put(
        Uri.parse('https://aerofind-api.onrender.com/customer/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint("Profile updated successfully");
        setState(() {
          isEditing = false;
          originalFirstName = firstNameController.text;
          originalLastName = lastNameController.text;
          originalPhone = phone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        debugPrint(
          "Failed to update profile: ${response.statusCode} ${response.body}",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }

    setState(() => isSaving = false);
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token'); // Dispose token
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Widget _buildProfileAvatar() {
    final bool hasProfilePicture =
        _profileImageUrl != null || _selectedProfileImage != null;

    return GestureDetector(
      onTap: (isUploadingImage || isDeletingImage) ? null : _onProfileAvatarTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _getProfileImageProvider(),
            child:
                (isUploadingImage || isDeletingImage)
                    ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF002F6C),
                shape: BoxShape.circle,
              ),
              child: Icon(
                // Show delete icon when editing and there's a profile picture, otherwise show camera
                (isEditing && hasProfilePicture)
                    ? Icons.delete
                    : Icons.camera_alt,
                color:
                    (isEditing && hasProfilePicture)
                        ? Colors.red
                        : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImageProvider() {
    // Priority: selected image > network image > placeholder
    if (_selectedProfileImage != null) {
      return FileImage(_selectedProfileImage!);
    } else if (_profileImageUrl != null &&
        _profileImageUrl!.trim().isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    } else {
      return const AssetImage('assets/placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false, // This completely disables back button and swipe gestures
      onPopInvokedWithResult: (didPop, result) {
        // Optional: Show a message when users try to navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Use logout button to exit'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: fetchProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipPath(
                      clipper: DeepArcClipper(),
                      child: Container(
                        height: size.height * 0.4,
                        width: double.infinity,
                        color: const Color(0xFF002F6C),
                      ),
                    ),
                    Positioned(
                      top: size.height * 0.10,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          _buildProfileAvatar(),
                          const SizedBox(height: 16),
                          Text(
                            "${firstNameController.text} ${lastNameController.text}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emailController.text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child:
                      isLoading
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      isEditing
                                          ? () {
                                            if (firstNameController.text !=
                                                    originalFirstName ||
                                                lastNameController.text !=
                                                    originalLastName ||
                                                contactController.text !=
                                                    originalPhone) {
                                              updateProfile();
                                            } else {
                                              setState(() {
                                                isEditing = false;
                                              });
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'No changes to save',
                                                  ),
                                                  backgroundColor: Colors.grey,
                                                ),
                                              );
                                            }
                                          }
                                          : () {
                                            setState(() {
                                              isEditing = true;
                                            });
                                          },
                                  icon:
                                      isSaving
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF002F6C),
                                            ),
                                          )
                                          : Icon(
                                            isEditing ? Icons.save : Icons.edit,
                                            size: 16,
                                            color: const Color(0xFF002F6C),
                                          ),
                                  label:
                                      isSaving
                                          ? const Text('')
                                          : Text(
                                            isEditing ? 'Save' : 'Edit',
                                            style: const TextStyle(
                                              color: Color(0xFF002F6C),
                                            ),
                                          ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF002F6C),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (isEditing) ...[
                                _buildTextField(
                                  'First Name',
                                  firstNameController,
                                ),
                                _buildTextField(
                                  'Last Name',
                                  lastNameController,
                                ),
                                _buildReadOnlyField(
                                  'Address',
                                  addressController,
                                ),
                                _buildPhoneField(
                                  'Contact Number',
                                  contactController,
                                ),
                                _buildReadOnlyField(
                                  'Email Address',
                                  emailController,
                                ),
                              ] else ...[
                                const Text(
                                  'Address',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  addressController.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Divider(height: 24),
                                const Text(
                                  'Contact Number',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  contactController.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Divider(height: 24),
                                GestureDetector(
                                  onTap: logoutUser,
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: Color(0xFF002F6C),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF002F6C)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhoneField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            hintText: '09XXXXXXXXX',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF002F6C)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            fillColor: Colors.grey[100],
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class DeepArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
