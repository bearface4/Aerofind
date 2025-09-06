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
  // Text controllers for seller data (read-only)
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
    debugPrint('[SELLER_PROFILE] Page initialized');
    // Get sellerId from route arguments after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      debugPrint('[SELLER_PROFILE] Route arguments: $args');
      if (args is int) {
        _sellerId = args;
        debugPrint('[SELLER_PROFILE] Valid seller_id received: $_sellerId');
        _loadTokenAndFetchProfile();
      } else {
        debugPrint(
          '[SELLER_PROFILE][ERROR] No seller ID provided in route arguments',
        );
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
    debugPrint('[SELLER_PROFILE] Disposing text controllers');
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
    debugPrint('[SELLER_PROFILE] Loading access token from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    debugPrint(
      '[SELLER_PROFILE] Loading seller profile for seller_id=$_sellerId',
    );
    debugPrint(
      '[SELLER_PROFILE] Token loaded: ${token != null && token.isNotEmpty}',
    );

    if (token == null || token.isEmpty) {
      debugPrint('[SELLER_PROFILE][ERROR] Missing access token');
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
    debugPrint(
      '[SELLER_PROFILE] Access token stored, proceeding to fetch seller profile',
    );
    await _fetchSellerProfile();
  }

  Future<void> _fetchSellerProfile() async {
    if (_sellerId == null) {
      debugPrint(
        '[SELLER_PROFILE][ERROR] Cannot fetch profile - seller_id is null',
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final endpoint =
        'https://aerofind-api.onrender.com/customer/seller/$_sellerId/profile';
    debugPrint('[SELLER_PROFILE][GET] $endpoint');
    debugPrint(
      '[SELLER_PROFILE][GET] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
    );

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final sw = Stopwatch()..start();

    try {
      debugPrint('[SELLER_PROFILE] Sending HTTP GET request...');
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      sw.stop();
      debugPrint(
        '[SELLER_PROFILE][RESP] Status: ${response.statusCode} (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[SELLER_PROFILE][RESP] Body length: ${response.body.length}');
      debugPrint(
        '[SELLER_PROFILE][RESP] Body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}',
      );

      if (response.statusCode == 200) {
        debugPrint('[SELLER_PROFILE] HTTP 200 - Parsing JSON response');
        final data = json.decode(response.body);
        debugPrint('[SELLER_PROFILE] Successfully loaded seller profile data');
        debugPrint('[SELLER_PROFILE] Store name: ${data['store_name']}');
        debugPrint('[SELLER_PROFILE] Store type: ${data['store_type']}');
        debugPrint('[SELLER_PROFILE] Email: ${data['email']}');
        debugPrint('[SELLER_PROFILE] Approval status: ${data['is_approved']}');
        debugPrint(
          '[SELLER_PROFILE] Average rating: ${data['average_rating']}',
        );
        debugPrint('[SELLER_PROFILE] Rating count: ${data['rating_count']}');
        debugPrint(
          '[SELLER_PROFILE] Has profile image: ${data['profile_image_url'] != null && data['profile_image_url'].toString().isNotEmpty}',
        );
        debugPrint(
          '[SELLER_PROFILE] Has banner image: ${data['banner_image_url'] != null && data['banner_image_url'].toString().isNotEmpty}',
        );
        debugPrint(
          '[SELLER_PROFILE] Has requirements file: ${data['requirements_file_url'] != null && data['requirements_file_url'].toString().isNotEmpty}',
        );

        if (!mounted) return;
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

        debugPrint('[SELLER_PROFILE] UI state updated successfully');
        debugPrint(
          '[SELLER_PROFILE] Profile loaded: ${data['store_name']} (seller_id: $_sellerId)',
        );
        debugPrint(
          '[SELLER_PROFILE] Requirements file URL: $_requirementsFileUrl',
        );
      } else if (response.statusCode == 401) {
        debugPrint(
          '[SELLER_PROFILE][ERROR] 401 Unauthorized - token may be expired',
        );
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
        debugPrint(
          '[SELLER_PROFILE][ERROR] 404 Seller not found for seller_id: $_sellerId',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller profile not found.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      } else {
        debugPrint(
          '[SELLER_PROFILE][ERROR] Failed to load profile: ${response.statusCode}',
        );
        debugPrint('[SELLER_PROFILE][ERROR] Response body: ${response.body}');
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
        '[SELLER_PROFILE][ERROR] Network error after ${sw.elapsedMilliseconds} ms: $e',
      );
      debugPrint('[SELLER_PROFILE][ERROR] Exception type: ${e.runtimeType}');
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
    debugPrint('[SELLER_PROFILE] Opening PDF viewer for URL: $url');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PdfViewerScreen(url: url)));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[SELLER_PROFILE] Building UI - isLoading: $_isLoading');
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
                    // Banner Image Section
                    _buildBannerSection(),

                    // Profile Avatar Section
                    _buildProfileAvatar(),
                    const SizedBox(height: 32),

                    // Store Information Card
                    _buildStoreInfoCard(),
                    const SizedBox(height: 16),

                    // Contact & Business Info Card
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
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        debugPrint(
                          '[SELLER_PROFILE] Banner image loaded successfully',
                        );
                        return child;
                      }
                      debugPrint(
                        '[SELLER_PROFILE] Loading banner image... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}',
                      );
                      return Container(
                        width: double.infinity,
                        height: 150,
                        color: Colors.grey.shade300,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      debugPrint(
                        '[SELLER_PROFILE] Failed to load banner image: $_bannerImageUrl',
                      );
                      return Image.asset(
                        'assets/placeholder.png',
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      );
                    },
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
    debugPrint(
      '[SELLER_PROFILE] Building profile avatar - has image: ${_profileImageUrl != null && _profileImageUrl!.isNotEmpty}',
    );
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
    debugPrint('[SELLER_PROFILE] Building store info card');
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

          // Store Name
          _buildReadOnlyTextField(
            label: "Store Name",
            controller: _storeNameController,
            icon: Icons.store,
          ),
          const SizedBox(height: 16),

          // Store Type
          _buildReadOnlyTextField(
            label: "Store Type",
            controller: _storeTypeController,
            icon: Icons.category,
          ),
          const SizedBox(height: 16),

          // Average Rating
          _buildReadOnlyTextField(
            label: "Average Rating",
            controller: _avgRatingController,
            icon: Icons.star,
          ),
          const SizedBox(height: 16),

          // Rating Count
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
    debugPrint('[SELLER_PROFILE] Building contact info card');
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

          // Email
          _buildReadOnlyTextField(
            label: "Email Address",
            controller: _emailController,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),

          // Address
          _buildReadOnlyTextField(
            label: "Business Address",
            controller: _addressController,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),

          // Delivery Fee
          _buildReadOnlyTextField(
            label: "Delivery Fee",
            controller: _deliveryFeeController,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 16),

          // Approval Status
          _buildReadOnlyTextField(
            label: "Business Status",
            controller: _approvalStatusController,
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: 16),

          // Requirements File (Clickable PDF Viewer)
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
                          onTap: () {
                            debugPrint(
                              '[SELLER_PROFILE] Tapped requirements file: $_requirementsFileUrl',
                            );
                            _openPdfViewer(_requirementsFileUrl!);
                          },
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

class PdfViewerScreen extends StatelessWidget {
  final String url;

  const PdfViewerScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    debugPrint('[PDF_VIEWER] Opening PDF: $url');
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
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          debugPrint(
            '[PDF_VIEWER] Document loaded successfully - Pages: ${details.document.pages.count}',
          );
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          debugPrint('[PDF_VIEWER] Failed to load document: ${details.error}');
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
