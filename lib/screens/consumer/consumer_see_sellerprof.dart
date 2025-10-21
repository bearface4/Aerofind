import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ConsumerSeeSellerProfilePage extends StatefulWidget {
  const ConsumerSeeSellerProfilePage({super.key});

  @override
  State<ConsumerSeeSellerProfilePage> createState() =>
      _ConsumerSeeSellerProfilePageState();
}

class _ConsumerSeeSellerProfilePageState
    extends State<ConsumerSeeSellerProfilePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeTypeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _deliveryFeeController = TextEditingController();
  final TextEditingController _approvalStatusController =
      TextEditingController();
  final TextEditingController _avgRatingController = TextEditingController();
  final TextEditingController _ratingCountController = TextEditingController();

  bool _isLoading = true;
  String? _profileImageUrl;
  String? _bannerImageUrl;
  String? _requirementsFileUrl;
  String? _token;
  int? _sellerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _sellerId = args;
        _loadTokenAndFetchProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid seller ID.'),
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
    _emailController.dispose();
    _storeNameController.dispose();
    _storeTypeController.dispose();
    _addressController.dispose();
    _deliveryFeeController.dispose();
    _approvalStatusController.dispose();
    _avgRatingController.dispose();
    _ratingCountController.dispose();
    super.dispose();
  }

  Future<void> _loadTokenAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
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
    await _fetchSellerProfile();
  }

  Future<void> _fetchSellerProfile() async {
    if (_sellerId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final endpoint =
        'https://aerofind-api.onrender.com/customer/seller/$_sellerId/profile';
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _emailController.text = data['email']?.toString() ?? '';
          _storeNameController.text = data['store_name']?.toString() ?? '';
          _storeTypeController.text = data['store_type']?.toString() ?? '';
          _addressController.text = data['address']?.toString() ?? '';
          _deliveryFeeController.text =
              '₱${data['delivery_fee']?.toString() ?? '0'}';
          _approvalStatusController.text =
              data['is_approved'] == true ? 'Approved' : 'Not Approved';
          _avgRatingController.text = data['average_rating']?.toString() ?? '0';
          _ratingCountController.text = data['rating_count']?.toString() ?? '0';

          _profileImageUrl = data['profile_image_url']?.toString();
          _bannerImageUrl = data['banner_image_url']?.toString();
          _requirementsFileUrl = data['requirements_file_url']?.toString();
          _isLoading = false;
        });
      } else {
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

  void _openPdfViewer(String url) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PdfViewerScreen(url: url)));
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
          "Seller Profile",
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
                    _buildBannerSection(),
                    _buildProfileAvatar(),
                    const SizedBox(height: 32),
                    _buildStoreInfoCard(),
                    const SizedBox(height: 16),
                    _buildContactInfoCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildBannerSection() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              _bannerImageUrl != null && _bannerImageUrl!.isNotEmpty
                  ? Image.network(
                    _bannerImageUrl!,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                  : Image.asset(
                    'assets/placeholder.png',
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
        ),
        const SizedBox(height: 16),
      ],
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
          _storeNameController.text.trim().isNotEmpty
              ? _storeNameController.text.trim()
              : "Store Profile",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInfoCard() {
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
            "Store Information",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildReadOnlyTextField(
            label: "Store Name",
            controller: _storeNameController,
            icon: Icons.store,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyTextField(
            label: "Store Type",
            controller: _storeTypeController,
            icon: Icons.category,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyTextField(
            label: "Average Rating",
            controller: _avgRatingController,
            icon: Icons.star,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyTextField(
            label: "Total Reviews",
            controller: _ratingCountController,
            icon: Icons.rate_review,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
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
            "Contact & Business Information",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildReadOnlyTextField(
            label: "Email Address",
            controller: _emailController,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyTextField(
            label: "Business Address",
            controller: _addressController,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyTextField(
            label: "Delivery Fee",
            controller: _deliveryFeeController,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyTextField(
            label: "Business Status",
            controller: _approvalStatusController,
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: 16),
          _buildRequirementsFileField(),
        ],
      ),
    );
  }

  Widget _buildRequirementsFileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Requirements Document",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _requirementsFileUrl != null &&
                            _requirementsFileUrl!.isNotEmpty
                        ? GestureDetector(
                          onTap: () => _openPdfViewer(_requirementsFileUrl!),
                          child: Text(
                            'View Document',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Color(0xFF00205B),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                        : Text(
                          'No document available',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ],
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
          enabled: false,
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

class PdfViewerScreen extends StatelessWidget {
  final String url;
  const PdfViewerScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "Requirements Document",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF002F6C),
          ),
        ),
      ),
      body: SfPdfViewer.network(
        url,
        onDocumentLoaded: (details) {},
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load document. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}
