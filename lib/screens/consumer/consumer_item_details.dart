import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerItemDetails extends StatefulWidget {
  const ConsumerItemDetails({super.key});

  @override
  _ConsumerItemDetailsState createState() => _ConsumerItemDetailsState();
}

class _ConsumerItemDetailsState extends State<ConsumerItemDetails> {
  int quantity = 1;
  final TextEditingController noteController = TextEditingController();

  Map<String, dynamic>? productData;
  bool isLoading = true;
  int? productId;

  String? _token;

  // Favorite state
  bool isFavorite = false;
  int? favoriteId; // Store favorite_id for DELETE

  // Profile fields
  int? _customerId;
  String? _customerEmail;
  String? _customerName; // Concatenated from profile

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    productId = args['id'];
    _loadTokenAndFetchData(productId!);
  }

  Future<void> _loadTokenAndFetchData(int id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('access_token');
    });
    // Fetch product first (open endpoint)
    await fetchProductDetails(id);
    // Then fetch favorites (requires token)
    await fetchFavoriteStatus(id);
    // Fetch profile for reports
    await fetchCustomerProfile();
  }

  Future<void> fetchProductDetails(int id) async {
    final url = Uri.parse(
      'https://aerofind-api.onrender.com/customer/products/$id',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        productData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  /// Fetch the list of favorites and check if this product is included
  Future<void> fetchFavoriteStatus(int id) async {
    if (_token == null) return;
    final url = Uri.parse(
      'https://aerofind-api.onrender.com/customer/favorites',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> favorites = json.decode(response.body);
        final fav = favorites.firstWhere(
          (f) => f['product_id'] == id,
          orElse: () => null,
        );
        setState(() {
          isFavorite = fav != null;
          favoriteId = fav != null ? fav['id'] : null;
        });
      } else if (response.statusCode == 401) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      // You can log or handle silently
      // print("❌ Failed to fetch favorite status: $e");
    }
  }

  /// Fetch customer profile to populate report fields
  Future<void> fetchCustomerProfile() async {
    if (_token == null) return;
    final url = Uri.parse('https://aerofind-api.onrender.com/customer/profile');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> profile = json.decode(response.body);
        final int? id = profile['id'];
        final String? firstName = profile['first_name'];
        final String? lastName = profile['last_name'];
        final String? middleName = profile['middle_name'];
        final String? suffix = profile['suffix'];
        // Email may be present in profile or not; attempt to read
        final String? email = profile['email'] ?? profile['customer_email'];

        final List<String> nameParts = [
          if (firstName != null && firstName.trim().isNotEmpty)
            firstName.trim(),
          if (middleName != null && middleName.trim().isNotEmpty)
            middleName.trim(),
          if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
          if (suffix != null && suffix.trim().isNotEmpty) suffix.trim(),
        ];
        final String combinedName =
            nameParts.isEmpty ? '' : nameParts.join(' ');

        setState(() {
          _customerId = id;
          _customerEmail = email;
          _customerName = combinedName.isNotEmpty ? combinedName : null;
        });
      } else if (response.statusCode == 401) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      // Handle silently; reporting will still work with nulls if API allows
    }
  }

  Future<void> addToCart() async {
    if (_token == null || productData == null) return;
    final url = Uri.parse(
      'https://aerofind-api.onrender.com/customer/cart/items',
    );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: json.encode({
        'product_id': productId,
        'quantity': quantity,
        'note': noteController.text,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final itemName = productData!['name'] ?? 'Item';
      final message =
          quantity > 1
              ? '$quantity $itemName added to cart.'
              : '$itemName added to cart';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    } else if (response.statusCode == 401) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add to cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Add favorite
  Future<void> addFavorite() async {
    if (_token == null || productData == null) return;
    final url = Uri.parse(
      'https://aerofind-api.onrender.com/customer/favorites',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'product_id': productId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchFavoriteStatus(productId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 401) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error adding to favorites'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Remove favorite
  Future<void> removeFavorite() async {
    if (_token == null || favoriteId == null) return;
    final url = Uri.parse(
      'https://aerofind-api.onrender.com/customer/favorites/$favoriteId',
    );
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          isFavorite = false;
          favoriteId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 401) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove from favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error removing from favorites'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Toggle favorite with dialog confirmation for removal
  Future<void> toggleFavorite() async {
    if (!isFavorite) {
      await addFavorite();
    } else {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Remove from favorites?'),
              content: const Text(
                'Are you sure you want to remove this item from your favorites?',
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black, // Text color black
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.black, // Text color black
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
      );
      if (confirm == true) {
        await removeFavorite();
      }
    }
  }

  // Helper to extract per-item delivery fee from seller.delivery_fee
  num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  double _extractItemDeliveryFeeFromSeller(Map<String, dynamic> productData) {
    final seller = productData['seller'];
    if (seller is Map) {
      final val = _asNum(seller['delivery_fee']);
      if (val != null) return val.toDouble();
    }
    return 0.0;
  }

  // Build a single-item order summary payload from current product and quantity
  Map<String, dynamic> _singleItemOrderArgs() {
    if (productData == null) return {};

    final double price =
        (productData!['price'] is num)
            ? (productData!['price'] as num).toDouble()
            : double.tryParse('${productData!['price']}') ?? 0.0;
    final int qty = quantity;
    final double subtotal = price * qty;
    final double perItemFee = _extractItemDeliveryFeeFromSeller(productData!);
    final double total = subtotal + perItemFee;

    final items = [
      {
        'id': productData!['id'],
        'quantity': qty,
        'product': {
          'id': productData!['id'],
          'name': productData!['name'],
          'price': price,
          'image_url': productData!['image_url'],
        },
      },
    ];

    return {
      // --- flags to make Checkout logic use single-item flow ---
      'buyNow': true,
      'product_id': productData!['id'],

      'items': items,
      'subtotal': subtotal,
      'deliveryFee': perItemFee,
      'total': total,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF001F5B);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (productData == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Failed to load product details.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.asset(
                        'assets/back.png',
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Item',
                            style: TextStyle(
                              color: Color(0xFF002363),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' Details',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => _buildReportDialog(context),
                      );
                    },
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.deepOrangeAccent,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product Image (with placeholder fallback)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _productImage(productData!['image_url']),
              ),
              const SizedBox(height: 24),

              // Title + Rating + Favorite
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      productData!['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text(
                          productData!['average_rating'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Favorite button
                  GestureDetector(
                    onTap: toggleFavorite,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                      color: isFavorite ? primaryColor : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Vendor Section
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.consumerstoreview,
                    arguments: {'seller_id': productData!['seller_id']},
                  );
                },
                child: Row(
                  children: [
                    Text(
                      productData!['store_name'] ?? 'View Store',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                productData!['description'] ?? '',
                style: const TextStyle(fontSize: 14.5, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 20),

              // Note Field
              const Text.rich(
                TextSpan(
                  text: "Add Note ",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  children: [
                    TextSpan(
                      text: "(optional)",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF002363)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'add notes here.',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quantity Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _quantityButton(
                    icon: Icons.remove,
                    onTap: () {
                      setState(() {
                        quantity = quantity > 1 ? quantity - 1 : 1;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _quantityButton(
                    icon: Icons.add,
                    onTap: () {
                      setState(() {
                        quantity++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Build single-item order summary and navigate to checkout
                        final args = _singleItemOrderArgs();
                        Navigator.pushNamed(
                          context,
                          AppRoutes.consumercheckout,
                          arguments: args,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: addToCart,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add to cart'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns image with graceful fallback to assets/placeholder.png
  /// when URL is null/empty/"null" or if the network image fails.
  Widget _productImage(dynamic url) {
    final String? s = url?.toString();
    final bool hasUrl =
        s != null && s.isNotEmpty && s.toLowerCase().trim() != 'null';
    if (hasUrl) {
      return Image.network(
        s!,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Image.asset(
              'assets/placeholder.png',
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
      );
    }
    return Image.asset(
      'assets/placeholder.png',
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.black),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildReportDialog(BuildContext context) {
    final TextEditingController _reportController = TextEditingController();
    bool _isReporting = false;

    Future<void> _submitReport(StateSetter setStateDialog) async {
      // Validate token
      if (_token == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }
      // Validate reason
      final reason = _reportController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a reason before submitting.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Validate product target
      if (productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing product information.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setStateDialog(() => _isReporting = true);

      final url = Uri.parse(
        'https://aerofind-api.onrender.com/customer/reports',
      );

      // Build payload with available profile fields
      final Map<String, dynamic> payload = {
        'report_type': 'product',
        'target_id': productId,
        'reason': reason,
        // Include profile fields when available
        if (_customerId != null) 'customer_id': _customerId,
        if (_customerEmail != null) 'customer_email': _customerEmail,
        if (_customerName != null && _customerName!.isNotEmpty)
          'customer_name': _customerName,
      };

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: json.encode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Optionally parse the response for confirmation
          // final Map<String, dynamic> data = json.decode(response.body);

          if (context.mounted) {
            Navigator.pop(context); // Close dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report submitted successfully.'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to "report submitted" screen as in previous flow
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.consumerreportsub,
            );
          }
        } else if (response.statusCode == 401) {
          if (context.mounted) {
            Navigator.pop(context); // Close dialog
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        } else {
          // Show server error message if available
          String msg = 'Failed to submit report';
          try {
            final body = json.decode(response.body);
            if (body is Map && body['detail'] != null) {
              msg = body['detail'].toString();
            }
          } catch (_) {}
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error submitting report.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (context.mounted) {
          setStateDialog(() => _isReporting = false);
        }
      }
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Report Product',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "If you believe there's an issue with this product, please let us know. Provide a brief reason for reporting this product in the field below.",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reportController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Input reason here",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child:
                      _isReporting
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF002363),
                              strokeWidth: 3,
                            ),
                          )
                          : ElevatedButton(
                            onPressed: () => _submitReport(setState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF001F5B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit report',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
