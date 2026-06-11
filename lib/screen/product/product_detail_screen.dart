// product_detail_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fullter_connection_api/models/product/Products.dart';
import 'package:http/http.dart' as httpClient;

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Products? product;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getProductDetail();
  }

  _getProductDetail() async {
    setState(() {
      isLoading = true;
    });

    try {
      var url = Uri.parse("https://dummyjson.com/products/${widget.productId}");
      var response = await httpClient.get(url);
      var mapResponse = jsonDecode(response.body);

      setState(() {
        product = Products.fromJson(mapResponse);
      });
    } catch (e) {
      debugPrint("Error fetching product detail: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text("Product Detail", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : product == null
          ? const Center(child: Text("Product not found"))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Image Gallery -----
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: product!.images?.isNotEmpty == true
                    ? product!.images!.length
                    : 1,
                itemBuilder: (context, index) {
                  String imageUrl =
                  product!.images?.isNotEmpty == true
                      ? product!.images![index]
                      : "${product!.thumbnail}";
                  return Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 60),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    "${product!.title}",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  // Brand & Category
                  Text(
                    "${product!.brand ?? ''} • ${product!.category ?? ''}",
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  // Price & Discount
                  Row(
                    children: [
                      Text(
                        "\$${product!.price}",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "-${product!.discountPercentage}%",
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Rating & Stock
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text("${product!.rating}"),
                      const SizedBox(width: 16),
                      Text("Stock: ${product!.stock}"),
                      const SizedBox(width: 4),
                      Text(
                        "(${product!.availabilityStatus ?? ''})",
                        style: TextStyle(
                          color: (product!.availabilityStatus ==
                              "Out of Stock")
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text("Description",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    "${product!.description}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  if (product!.tags != null &&
                      product!.tags!.isNotEmpty) ...[
                    const Text("Tags",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product!.tags!
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Additional Info
                  const Text("Additional Information",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _infoRow("SKU", product!.sku),
                  _infoRow("Weight", "${product!.weight} g"),
                  if (product!.dimensions != null)
                    _infoRow("Dimensions",
                        "${product!.dimensions!.width} x ${product!.dimensions!.height} x ${product!.dimensions!.depth}"),
                  _infoRow("Warranty", product!.warrantyInformation),
                  _infoRow("Shipping", product!.shippingInformation),
                  _infoRow("Return Policy", product!.returnPolicy),
                  _infoRow("Min Order Qty",
                      "${product!.minimumOrderQuantity}"),
                  const SizedBox(height: 16),

                  // Reviews
                  if (product!.reviews != null &&
                      product!.reviews!.isNotEmpty) ...[
                    const Text("Reviews",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...product!.reviews!.map((review) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "${review.reviewerName}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(
                                  5,
                                      (i) => Icon(
                                    Icons.star,
                                    size: 14,
                                    color: i < (review.rating ?? 0).toInt()
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("${review.comment}"),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}