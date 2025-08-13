import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerProfilePage extends StatefulWidget {
  const ConsumerProfilePage({super.key});

  @override
  State<ConsumerProfilePage> createState() => _ConsumerProfilePageState();
}

class _ConsumerProfilePageState extends State<ConsumerProfilePage> {
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  late String originalFirstName;
  late String originalLastName;
  late String originalPhone;

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

        setState(() {
          firstNameController.text = data['first_name'] ?? '';
          lastNameController.text = data['last_name'] ?? '';
          contactController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? '';
          addressController.text = "No address on file"; // placeholder

          originalFirstName = firstNameController.text;
          originalLastName = lastNameController.text;
          originalPhone = contactController.text;
        });
      } else {
        debugPrint("Failed to fetch profile: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }

    setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
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
                        const CircleAvatar(
                          radius: 60,
                          backgroundImage: AssetImage('assets/placeholder.png'),
                        ),
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
                              _buildTextField('Last Name', lastNameController),
                              _buildTextField('Address', addressController),
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
                                child: Row(
                                  children: const [
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
