import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  // Text controllers for customer data (read-only)
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  String? _profileImageUrl;
  String? _token;
  int? _customerId;

  @override
  void initState() {
    super.initState();
    // Get customerId from route arguments after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _customerId = args;
        _loadTokenAndFetchProfile();
      } else {
        debugPrint(
          '[PROFILE][ERROR] No customer ID provided in route arguments',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid customer ID.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadTokenAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    debugPrint(
      '[PROFILE] Loading customer profile for customer_id=$_customerId',
    );
    debugPrint('[PROFILE] Token loaded: ${token != null && token.isNotEmpty}');

    if (token == null || token.isEmpty) {
      debugPrint('[PROFILE][ERROR] Missing access token');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing access token. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _token = token;
    await _fetchCustomerProfile();
  }

  Future<void> _fetchCustomerProfile() async {
    if (_customerId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final endpoint =
        'https://aerofind-api.onrender.com/seller/customer/$_customerId/profile';
    debugPrint('[PROFILE][GET] $endpoint');
    debugPrint(
      '[PROFILE][GET] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
    );

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final sw = Stopwatch()..start();

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      sw.stop();
      debugPrint(
        '[PROFILE][RESP] Status: ${response.statusCode} (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[PROFILE][RESP] Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[PROFILE] Successfully loaded customer profile data');

        if (!mounted) return;
        setState(() {
          _firstNameController.text = data['first_name']?.toString() ?? '';
          _lastNameController.text = data['last_name']?.toString() ?? '';
          _emailController.text = data['email']?.toString() ?? '';
          _phoneController.text = data['phone']?.toString() ?? '';
          _profileImageUrl = data['profile_pic']?.toString();
          _isLoading = false;
        });

        debugPrint(
          '[PROFILE] Profile loaded: ${data['first_name']} ${data['last_name']}',
        );
      } else if (response.statusCode == 401) {
        debugPrint('[PROFILE][ERROR] 401 Unauthorized');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        debugPrint('[PROFILE][ERROR] 404 Customer not found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer profile not found.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      } else {
        debugPrint(
          '[PROFILE][ERROR] Failed to load profile: ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile (${response.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      sw.stop();
      debugPrint(
        '[PROFILE][ERROR] Network error after ${sw.elapsedMilliseconds} ms: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "Customer Profile",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF002F6C),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Avatar Section
                    _buildProfileAvatar(),
                    const SizedBox(height: 32),

                    // Customer Information Form
                    _buildCustomerInfoCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileAvatar() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade300,
          backgroundImage:
              _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? NetworkImage(_profileImageUrl!)
                  : const AssetImage('assets/placeholder.png') as ImageProvider,
        ),
        const SizedBox(height: 16),
        Text(
          "${_firstNameController.text} ${_lastNameController.text}".trim(),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // First Name
          _buildReadOnlyTextField(
            label: "First Name",
            controller: _firstNameController,
            icon: Icons.person,
          ),
          const SizedBox(height: 16),

          // Last Name
          _buildReadOnlyTextField(
            label: "Last Name",
            controller: _lastNameController,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 24),

          Text(
            "Contact Information",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Email
          _buildReadOnlyTextField(
            label: "Email Address",
            controller: _emailController,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),

          // Phone
          _buildReadOnlyTextField(
            label: "Phone Number",
            controller: _phoneController,
            icon: Icons.phone_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: false, // Makes it non-editable
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
