import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerStoreViewer extends StatefulWidget {
  @override
  _ConsumerStoreViewerState createState() => _ConsumerStoreViewerState();
}

class _ConsumerStoreViewerState extends State<ConsumerStoreViewer> {
  List<dynamic> products = [];
  bool isLoadingProducts = true;

  Map<String, dynamic>? storeProfile;
  bool isLoadingProfile = true;

  int? sellerId;

  // Track which product IDs are currently being added to cart
  final Set<int> _addingToCart = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    sellerId = args?['seller_id'];

    if (sellerId != null) {
      fetchStoreProfile(sellerId!);
      fetchProducts(sellerId!);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> fetchStoreProfile(int sellerId) async {
    setState(() {
      isLoadingProfile = true;
    });

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(
          'https://aerofind-api.onrender.com/customer/seller/$sellerId/profile',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          storeProfile = json.decode(response.body) as Map<String, dynamic>;
          isLoadingProfile = false;
        });
      } else {
        setState(() {
          isLoadingProfile = false;
        });
        debugPrint('Failed to load store profile: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingProfile = false;
      });
      debugPrint('Error loading store profile: $e');
    }
  }

  Future<void> fetchProducts(int sellerId) async {
    setState(() {
      isLoadingProducts = true;
    });

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(
          'https://aerofind-api.onrender.com/customer/seller/$sellerId/products',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body) as List<dynamic>;
          isLoadingProducts = false;
        });
      } else {
        setState(() {
          isLoadingProducts = false;
        });
        debugPrint('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingProducts = false;
      });
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _refreshAll() async {
    if (sellerId == null) return;
    await Future.wait([fetchStoreProfile(sellerId!), fetchProducts(sellerId!)]);
  }

  // Return success/failure to control UI state
  Future<bool> addToCart(int productId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse('https://aerofind-api.onrender.com/customer/cart/items'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({'product_id': productId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$name added to cart"),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to add item to cart"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _handleAddToCartTap(int productId, String name) async {
    if (_addingToCart.contains(productId)) return; // prevent double taps
    setState(() {
      _addingToCart.add(productId);
    });
    try {
      await addToCart(productId, name);
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart.remove(productId);
        });
      }
    }
  }

  // Helper to extract per-item delivery fee from seller data or store profile
  num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  double _extractDeliveryFee(Map<String, dynamic> product) {
    // First try to get delivery fee from product's seller data
    final seller = product['seller'];
    if (seller is Map) {
      final val = _asNum(seller['delivery_fee']);
      if (val != null) return val.toDouble();
    }

    // Fallback to store profile delivery fee
    if (storeProfile != null) {
      final val = _asNum(storeProfile!['delivery_fee']);
      if (val != null) return val.toDouble();
    }

    return 0.0;
  }

  // Build a single-item order summary payload from a product
  Map<String, dynamic> _singleItemOrderArgs(Map<String, dynamic> product) {
    final double price =
        (product['price'] is num)
            ? (product['price'] as num).toDouble()
            : double.tryParse('${product['price']}') ?? 0.0;
    const int qty = 1;
    final double subtotal = price * qty;
    final double perItemFee = _extractDeliveryFee(product);
    final double total = subtotal + perItemFee;

    final items = [
      {
        'id': product['id'],
        'quantity': qty,
        'product': {
          'id': product['id'],
          'name': product['name'],
          'price': price,
          'image_url': product['image_url'],
        },
      },
    ];

    return {
      // --- flags to make Checkout logic use single-item flow ---
      'buyNow': true,
      'product_id': product['id'],

      'items': items,
      'subtotal': subtotal,
      'deliveryFee': perItemFee,
      'total': total,
    };
  }

  void _buyNow(Map<String, dynamic> product) {
    // Build single-item order summary and navigate to checkout
    final args = _singleItemOrderArgs(product);
    Navigator.pushNamed(context, AppRoutes.consumercheckout, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).padding.bottom + 20; // responsive bottom space

    final bannerUrl = storeProfile?['banner_image_url'] as String?;
    final profileUrl = storeProfile?['profile_image_url'] as String?;
    final hasBanner = (bannerUrl != null && bannerUrl.trim().isNotEmpty);
    final hasProfile = (profileUrl != null && profileUrl.trim().isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // ===== Robust banner that always fills width & height =====
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      child:
                          hasBanner
                              ? Image.network(
                                bannerUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Image.asset(
                                      'assets/placeholder.png',
                                      fit: BoxFit.cover,
                                    ),
                              )
                              : Image.asset(
                                'assets/placeholder.png',
                                fit: BoxFit.cover,
                              ),
                    ),
                    Container(color: Colors.black.withOpacity(0.35)),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
              Expanded(
                // Pull-to-refresh on the product grid
                child:
                    isLoadingProducts
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: _refreshAll,
                          displacement: 24,
                          child: GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              bottomInset,
                            ),
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.65,
                                ),
                            itemBuilder: (context, index) {
                              final item =
                                  products[index] as Map<String, dynamic>;
                              final imageUrl =
                                  (item['image_url'] ?? '') as String;
                              final productId = item['id'] as int;
                              final isAdding = _addingToCart.contains(
                                productId,
                              );

                              return MenuCard(
                                imageUrl: imageUrl,
                                name: item['name']?.toString() ?? 'Unknown',
                                price: '₱${item['price'] ?? '0'}',
                                rating:
                                    (item['average_rating']?.toString() ??
                                        '4.0'),
                                isAddingToCart: isAdding,
                                onAddToCart:
                                    () => _handleAddToCartTap(
                                      productId,
                                      item['name'] as String,
                                    ),
                                onBuyNow: () => _buyNow(item),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
          // Store card overlays the banner
          Positioned(
            top: 180,
            left: 20,
            right: 20,
            child:
                isLoadingProfile && storeProfile == null
                    ? const _StoreCardSkeleton()
                    : StoreCard(
                      storeName:
                          storeProfile?['store_name']?.toString() ?? 'Store',
                      address: storeProfile?['address']?.toString() ?? '',
                      averageRating:
                          (storeProfile?['average_rating'] ?? 0).toDouble(),
                      ratingCount: (storeProfile?['rating_count'] ?? 0) as int,
                      deliveryFee:
                          (storeProfile?['delivery_fee'] ?? 0).toDouble(),
                      profileImageUrl: hasProfile ? profileUrl : null,
                    ),
          ),
        ],
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  final String storeName;
  final String address;
  final double averageRating;
  final int ratingCount;
  final double deliveryFee;
  final String? profileImageUrl;

  const StoreCard({
    super.key,
    required this.storeName,
    required this.address,
    required this.averageRating,
    required this.ratingCount,
    required this.deliveryFee,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final image =
        (profileImageUrl != null && profileImageUrl!.trim().isNotEmpty)
            ? _NetworkOrPlaceholderImage(
              url: profileImageUrl!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholderAsset: 'assets/placeholder.png',
              borderRadius: BorderRadius.circular(12),
            )
            : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/placeholder.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          image,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (address.isNotEmpty)
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      ' ($ratingCount)',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${deliveryFee.toStringAsFixed(deliveryFee % 1 == 0 ? 0 : 2)}',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCardSkeleton extends StatelessWidget {
  const _StoreCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonLine(width: 140),
                const SizedBox(height: 6),
                _skeletonLine(width: 180),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _skeletonLine(width: 40),
                    const SizedBox(width: 8),
                    _skeletonLine(width: 60),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine({double width = 100}) => Container(
    width: width,
    height: 12,
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class MenuCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String price;
  final String rating;
  final bool isAddingToCart;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const MenuCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.rating,
    required this.isAddingToCart,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = imageUrl.startsWith('http');
    const darkBlue = Color(0xFF002363);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  isNetworkImage
                      ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
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
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          price,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff002366),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Buy Now",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Cart button with loading state
            GestureDetector(
              onTap: isAddingToCart ? null : onAddToCart,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: darkBlue,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child:
                      isAddingToCart
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: darkBlue, // dark blue spinner
                            ),
                          )
                          : const Icon(
                            Icons.shopping_cart_outlined,
                            size: 16,
                            color: darkBlue,
                          ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper widget that tries network image first with placeholder fallback.
class _NetworkOrPlaceholderImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final String placeholderAsset;
  final BorderRadius? borderRadius;

  const _NetworkOrPlaceholderImage({
    required this.url,
    required this.placeholderAsset,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  });

  bool get _looksLikeNetwork => url.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final image =
        (_looksLikeNetwork)
            ? Image.network(
              url,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  placeholderAsset,
                  width: width,
                  height: height,
                  fit: fit,
                );
              },
            )
            : Image.asset(
              placeholderAsset,
              width: width,
              height: height,
              fit: fit,
            );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: image,
      );
    }
    return image;
  }
}
