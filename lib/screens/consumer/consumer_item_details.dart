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

  bool isFavorite = false;
  int? favoriteId; // ✅ Store favorite_id for DELETE

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
    await fetchProductDetails(id);
    await fetchFavoriteStatus(id);
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

  /// ✅ Fetch the list of favorites and check if this product is included
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
      print("❌ Failed to fetch favorite status: $e");
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

  /// ✅ Add favorite
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

  /// ✅ Remove favorite
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

  /// ✅ Toggle favorite with dialog confirmation for removal
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
                    foregroundColor: Colors.black, // ✅ Text color black
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.black, // ✅ Text color black
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

              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  productData!['image_url'],
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
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

                  /// ✅ Favorite button
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
                      onPressed: () {},
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
                            onPressed: () {
                              setState(() => _isReporting = true);
                              Future.delayed(const Duration(seconds: 2), () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.consumerreportsub,
                                  arguments: {'id': productId},
                                );
                              });
                            },
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
