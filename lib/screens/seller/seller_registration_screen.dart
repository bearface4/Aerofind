import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:aerofind/routes/app_routes.dart';
import 'package:http_parser/http_parser.dart';

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() =>
      _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _selectedStoreType;
  List<int>? _requirementsFileBytes;
  String? _selectedFileName;

  bool _isLoading = false;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade500),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF002F6C), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = true}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 15),
        children:
            isRequired
                ? const [
                  TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                ]
                : null,
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) =>
      (value == null || value.trim().isEmpty) ? '$fieldName is required' : null;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email address is required';

    // Allow uppercase in username, but enforce exact lowercase @gmail.com domain
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
      caseSensitive: true, // domain must be exactly lowercase
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Email must be a valid address ending with @gmail.com';
    }

    return null;
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a store type';
    }
    return null;
  }

  String? _validateRequirementsFile() {
    if (_requirementsFileBytes == null) {
      return 'Requirements file is required';
    }
    return null;
  }

  bool _isPdfFile(String fileName, List<int> fileBytes) {
    // Check by file extension first
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      return false;
    }

    // Check MIME type by extension
    final mimeType = lookupMimeType(fileName);
    if (mimeType == 'application/pdf') {
      return true;
    }

    // Check MIME type by file header bytes (more reliable)
    final mimeTypeByHeader = lookupMimeType(fileName, headerBytes: fileBytes);
    return mimeTypeByHeader == 'application/pdf';
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        PlatformFile file = result.files.single;

        // Check file size (5MB = 5 * 1024 * 1024 bytes)
        const int maxFileSize = 5 * 1024 * 1024;
        if (file.size > maxFileSize) {
          _showErrorDialog('File size must be less than 5MB');
          return;
        }

        // Validate that it's actually a PDF file
        if (!_isPdfFile(file.name, file.bytes!)) {
          _showErrorDialog('Please select a valid PDF file');
          return;
        }

        setState(() {
          _requirementsFileBytes = file.bytes!;
          _selectedFileName = file.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking PDF file: $e");
      _showErrorDialog('Error selecting PDF file. Please try again.');
    }
  }

  Future<void> _registerSeller() async {
    final url = Uri.parse('https://aerofind-api.onrender.com/seller/register');

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add form fields
      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['password'] = "";
      request.fields['store_name'] = _storeNameCtrl.text.trim();
      request.fields['latitude'] = "0";
      request.fields['longitude'] = "0";
      request.fields['store_type'] = _selectedStoreType!;
      request.fields['address'] = _addressCtrl.text.trim();

      // Add file as multipart file with explicit content type
      if (_requirementsFileBytes != null && _selectedFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'requirements_file',
            _requirementsFileBytes!,
            filename: _selectedFileName!,
            contentType: MediaType(
              'application',
              'pdf',
            ), // Explicitly set PDF MIME type
          ),
        );
      }

      debugPrint("📨 Sending multipart request to: $url");
      debugPrint("📨 Form fields: ${request.fields.keys.toList()}");
      debugPrint(
        "📨 Files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.contentType})').toList()}",
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("📨 Status Code: ${response.statusCode}");
      debugPrint("📨 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.sellerregistrationpending,
        );
      } else {
        try {
          final Map<String, dynamic> json = jsonDecode(response.body);
          if (json['detail'] is List) {
            // Handle validation errors array
            String errorMessage = 'Registration failed:\n';
            for (var error in json['detail']) {
              if (error['msg'] != null) {
                errorMessage += '• ${error['msg']}\n';
              }
            }
            _showErrorDialog(errorMessage.trim());
          } else {
            _showErrorDialog(json['detail'] ?? 'Registration failed');
          }
        } catch (_) {
          _showErrorDialog('Unexpected response from server');
        }
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      _showErrorDialog('Something went wrong. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Registration Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002F6C),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Curved white card area ──
            Positioned.fill(
              top: 100,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(80)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Store Name
                          _buildFieldLabel('Store Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _storeNameCtrl,
                            decoration: _fieldDecoration('Input store name'),
                            validator:
                                (value) =>
                                    _validateRequired(value, 'Store name'),
                          ),
                          const SizedBox(height: 24),

                          // Store Type
                          _buildFieldLabel('Store Type'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedStoreType,
                            decoration: _fieldDecoration(''),
                            hint: const Text(
                              'Select store type',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                            style: const TextStyle(color: Colors.black),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: 'Snacks',
                                child: Text('Snacks'),
                              ),
                              DropdownMenuItem(
                                value: 'Beverage',
                                child: Text('Beverage'),
                              ),
                              DropdownMenuItem(
                                value: 'Printing',
                                child: Text('Printing'),
                              ),
                              DropdownMenuItem(
                                value: 'Clothing',
                                child: Text('Clothing'),
                              ),
                              DropdownMenuItem(
                                value: 'Health',
                                child: Text('Health'),
                              ),
                              DropdownMenuItem(
                                value: 'Beauty',
                                child: Text('Beauty'),
                              ),
                              DropdownMenuItem(
                                value: 'School Supplies',
                                child: Text('School Supplies'),
                              ),
                              DropdownMenuItem(
                                value: 'General',
                                child: Text('General'),
                              ),
                              DropdownMenuItem(
                                value: 'Aviation/Aeronautics',
                                child: Text('Aviation/Aeronautics'),
                              ),
                            ],
                            onChanged:
                                (val) =>
                                    setState(() => _selectedStoreType = val),
                            validator: _validateDropdown,
                          ),
                          const SizedBox(height: 24),

                          // Address
                          _buildFieldLabel('Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: _fieldDecoration('Input store address'),
                            validator:
                                (value) => _validateRequired(value, 'Address'),
                          ),
                          const SizedBox(height: 24),

                          // Email Address
                          _buildFieldLabel('Email Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _fieldDecoration('Input email address'),
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 24),

                          // Requirements File Upload - REQUIRED
                          _buildFieldLabel('Upload Requirements File (PDF)'),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    _requirementsFileBytes == null
                                        ? Colors.red.shade300
                                        : Colors.green.shade500,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _requirementsFileBytes != null
                                          ? Icons.check_circle
                                          : Icons.upload_file,
                                      color:
                                          _requirementsFileBytes != null
                                              ? Colors.green.shade600
                                              : Colors.red.shade400,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedFileName ?? 'No file selected',
                                        style: TextStyle(
                                          color:
                                              _selectedFileName != null
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade400,
                                          fontSize: 14,
                                          fontWeight:
                                              _selectedFileName != null
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _pickPdfFile,
                                  icon: const Icon(Icons.folder_open, size: 16),
                                  label: Text(
                                    _requirementsFileBytes != null
                                        ? 'Change PDF File'
                                        : 'Select PDF File',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF002F6C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Max file size: 5MB • PDF file only • Required',
                                  style: TextStyle(
                                    color:
                                        _requirementsFileBytes != null
                                            ? Colors.green.shade600
                                            : Colors.red.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                                if (_requirementsFileBytes == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Requirements file is required',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Register Button or Loader
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child:
                                _isLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF002F6C),
                                            ),
                                      ),
                                    )
                                    : ElevatedButton(
                                      onPressed: () {
                                        // Validate PDF file first
                                        String? fileError =
                                            _validateRequirementsFile();
                                        if (fileError != null) {
                                          _showErrorDialog(fileError);
                                          return;
                                        }

                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          setState(() => _isLoading = true);
                                          _registerSeller();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF002F6C,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Title Text ──
            const Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Register as Seller',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
