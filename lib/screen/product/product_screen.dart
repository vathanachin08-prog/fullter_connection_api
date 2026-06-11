// product_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fullter_connection_api/models/product/Product_response.dart';
import 'package:fullter_connection_api/models/product/Products.dart';
import 'package:http/http.dart' as httpClient;

import 'product_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  // ====================================================
  // ⚙️ កំណត់ត្រង់នេះបាន — Configurable Settings
  // ====================================================
  final int limit = 3; // ចំនួន product ក្នុងមួយ page
  final Duration loadMoreDelay =
  const Duration(seconds: 1); // delay មុន load page បន្ទាប់
  final Duration initialLoadDelay =
  const Duration(milliseconds: 500); // delay ពេល load page ដំបូង
  // ====================================================

  List<Products> productList = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isSearching = false;

  int skip = 0;
  int total = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getAllProduct();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (isLoadingMore || isLoading) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (productList.length < total) {
        _loadMore();
      }
    }
  }

  // Initial load / refresh / new search
  _getAllProduct() async {
    setState(() {
      isLoading = true;
      skip = 0;
    });

    try {
      var url = isSearching
          ? Uri.parse(
          "https://dummyjson.com/products/search?q=$searchQuery&limit=$limit&skip=$skip")
          : Uri.parse(
          "https://dummyjson.com/products?limit=$limit&skip=$skip");

      var response = await httpClient.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Request timeout"),
      );

      // delay សិប្បនិម្មិត ពេល load ដំបូង
      await Future.delayed(initialLoadDelay);

      var mapResponse = jsonDecode(response.body);
      var productResponse = ProductResponse.fromJson(mapResponse);

      setState(() {
        productList = productResponse.products ?? [];
        total = productResponse.total ?? 0;
        skip = productList.length;
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  // Load next page (pagination)
  _loadMore() async {
    if (isLoadingMore || isLoading) return;

    setState(() {
      isLoadingMore = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      var url = isSearching
          ? Uri.parse(
          "https://dummyjson.com/products/search?q=$searchQuery&limit=$limit&skip=$skip")
          : Uri.parse(
          "https://dummyjson.com/products?limit=$limit&skip=$skip");

      var response = await httpClient.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Request timeout"),
      );

      var mapResponse = jsonDecode(response.body);
      var productResponse = ProductResponse.fromJson(mapResponse);

      // ⏳ delay សិប្បនិម្មិត មុនបង្ហាញ page បន្ទាប់
      await Future.delayed(loadMoreDelay);

      if (productResponse.products != null &&
          productResponse.products!.isNotEmpty) {
        setState(() {
          productList.addAll(productResponse.products!);
          total = productResponse.total ?? total;
          skip = productList.length;
        });
      }
    } catch (e) {
      debugPrint("Error loading more products: $e");
    }

    debugPrint("LoadMore took: ${stopwatch.elapsedMilliseconds} ms");

    setState(() {
      isLoadingMore = false;
    });
  }

  // Search with debounce (waits 500ms after typing stops)
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = value.trim();
        isSearching = searchQuery.isNotEmpty;
      });
      _getAllProduct();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text("Products", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
        child: Column(
          children: [
            // ----- Search Bar -----
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = "";
                      isSearching = false;
                    });
                    _getAllProduct();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.black12,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ----- List / Loading -----
            Expanded(
              child: isLoading
                  ? const Center(
                  child: CircularProgressIndicator(color: Colors.cyan))
                  : productList.isEmpty
                  ? const Center(child: Text("No products found"))
                  : RefreshIndicator(
                backgroundColor: Colors.cyan,
                color: Colors.white,
                onRefresh: () async {
                  await _getAllProduct();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount:
                  productList.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == productList.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                                color: Colors.cyan),
                            const SizedBox(height: 8),
                            Text(
                              "Loading more products...",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    var product = productList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(
                                    productId: product.id!),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                            top: 10, bottom: 10),
                        decoration: const BoxDecoration(
                          color: Colors.black12,
                          borderRadius:
                          BorderRadius.all(Radius.circular(20)),
                        ),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius:
                              const BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              child: SizedBox(
                                width: double.infinity,
                                height: 180,
                                child: Image.network(
                                  "${product.thumbnail}",
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child,
                                      loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return const Center(
                                      child:
                                      CircularProgressIndicator(
                                          color: Colors.cyan),
                                    );
                                  },
                                  errorBuilder: (context, error,
                                      stackTrace) =>
                                  const Icon(Icons
                                      .image_not_supported),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                "${product.title}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10),
                              child: Text(
                                "Price : \$${product.price}",
                                style:
                                const TextStyle(fontSize: 14),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              child: Text(
                                "Discount : ${product.discountPercentage}%",
                                style:
                                const TextStyle(fontSize: 14),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                "${product.description}",
                                style:
                                const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}