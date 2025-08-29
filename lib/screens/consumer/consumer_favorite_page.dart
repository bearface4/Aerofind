import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerFavoritePage extends StatefulWidget {
  const ConsumerFavoritePage({super.key});

  @override
  State<ConsumerFavoritePage> createState() => _ConsumerFavoritePageState();
}

class _ConsumerFavoritePageState extends State<ConsumerFavoritePage> {
  List<dynamic> favorites = [];
  bool isLoading = true;
  bool hasError = false;
  String? accessToken;

  @override
  void initState() {
    super.initState();
    loadTokenAndFetchFavorites();
  }

  Future<void> loadTokenAndFetchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    debugPrint("🔑 Loaded access_token from SharedPreferences: $token");

    if (token == null) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      debugPrint("❌ No access token found. Cannot fetch favorites.");
      return;
    }

    setState(() {
      accessToken = token;
    });

    await fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    const String url = "https://aerofind-api.onrender.com/customer/favorites";

    try {
      debugPrint("📡 GET $url");
      debugPrint("🔑 Using Access Token: $accessToken");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint("📡 Status Code: ${response.statusCode}");
      debugPrint("📦 Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        for (var fav in data) {
          final product = fav['product'] ?? {};
          final seller = product['seller'] ?? {};
          final storeName = seller['store_name'];
          debugPrint("---- FAVORITE ITEM ----");
          debugPrint("Favorite ID: ${fav['id']}");
          debugPrint("Product ID: ${fav['product_id']}");
          debugPrint("Name: ${product['name']}");
          debugPrint("Price: ${product['price']}");
          debugPrint("Description: ${product['description']}");
          debugPrint("Stocks: ${product['stocks']}");
          debugPrint("Seller ID: ${product['seller_id']}");
          debugPrint("Store Name (nested): $storeName");
          debugPrint("Average Rating: ${product['average_rating']}");
          debugPrint("Rating Count: ${product['rating_count']}");
          debugPrint("Image URL: ${product['image_url']}");
          debugPrint(
            "Categories: ${(product['categories'] as List?)?.join(', ') ?? ''}",
          );
        }

        setState(() {
          favorites = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      debugPrint("❌ Error fetching favorites: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> removeFavorite(int favoriteId) async {
    final String url =
        "https://aerofind-api.onrender.com/customer/favorites/$favoriteId";

    try {
      debugPrint("🗑 DELETE $url");
      debugPrint("🔑 Using Access Token: $accessToken");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint("📡 Status Code: ${response.statusCode}");
      debugPrint("📦 Raw Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          favorites.removeWhere((fav) => fav['id'] == favoriteId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to remove favorite');
      }
    } catch (e) {
      debugPrint("❌ Error removing favorite: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error removing favorite',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmRemoveFavorite(int favoriteId) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove from Favorites?'),
            content: const Text(
              'Are you sure you want to remove this item from your favorites?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );

    if (shouldRemove == true) {
      await removeFavorite(favoriteId);
    }
  }

  void _navigateToProductDetails(int productId) {
    debugPrint("🔗 Navigating to product details with ID: $productId");
    Navigator.pushNamed(
      context,
      AppRoutes.consumeritem,
      arguments: {'id': productId},
    );
  }

  void _navigateToStoreView(int sellerId) {
    debugPrint("🏪 Navigating to store view with seller ID: $sellerId");
    Navigator.pushNamed(
      context,
      AppRoutes.consumerstoreview,
      arguments: {'seller_id': sellerId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "My",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002F6C),
                      ),
                    ),
                    TextSpan(
                      text: " Favorites",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),

              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasError)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchFavorites,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 200),
                        const Center(
                          child: Text(
                            'Failed to load favorites',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: ElevatedButton(
                            onPressed: fetchFavorites,
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (favorites.isEmpty)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchFavorites,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No favorites found')),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchFavorites,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: favorites.length,
                      separatorBuilder:
                          (context, index) => const Divider(
                            color: Colors.black12,
                            thickness: 1,
                            height: 32,
                          ),
                      itemBuilder: (context, index) {
                        final fav = favorites[index];
                        final product = fav['product'] ?? {};
                        final seller = product['seller'] ?? {};
                        final String storeName =
                            (seller['store_name'] ?? '').toString();
                        final int productId = product['id'] ?? 0;
                        final int sellerId = seller['id'] ?? 0;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _navigateToProductDetails(productId),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product['image_url'] ??
                                      'https://via.placeholder.com/100',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                        size: 50,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              text:
                                                  storeName.isNotEmpty
                                                      ? storeName
                                                      : 'N/A',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              recognizer:
                                                  TapGestureRecognizer()
                                                    ..onTap = () {
                                                      if (sellerId > 0) {
                                                        _navigateToStoreView(
                                                          sellerId,
                                                        );
                                                      }
                                                    },
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "₱ ${product['price']?.toString() ?? ''}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 9),
                                    child: GestureDetector(
                                      onTap:
                                          () =>
                                              confirmRemoveFavorite(fav['id']),
                                      child: const Icon(
                                        Icons.favorite,
                                        color: Color(0xFF002F6C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
