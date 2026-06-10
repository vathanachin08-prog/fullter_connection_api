import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fullter_connection_api/models/product/Product_response.dart';
import 'package:fullter_connection_api/models/product/Products.dart';
import 'package:http/http.dart' as httpClient;

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Products> productList = [];
  bool isLoading = false;
  @override
  void initState() {
    _getAllProduct();
    super.initState();
  }

  _getAllProduct() async {
    setState(() {
      isLoading = true;
    });
    var url = Uri.parse("https://dummyjson.com/products");
    var response = await httpClient.get(url);
    var mapResponse = jsonDecode(response.body);
    var productResponse = ProductResponse.fromJson(mapResponse);
    if (productResponse.products!.isNotEmpty) {
      setState(() {
        productList = [];
        productList.addAll(productResponse.products!);
      });
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
        title: Text("Products", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        padding: EdgeInsets.only(left: 16, right: 16),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.cyan))
            : RefreshIndicator(
                backgroundColor: Colors.cyan,
                color: Colors.white,
                onRefresh: () async {
                  _getAllProduct();
                },
                child: ListView.builder(
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    var product = productList[index];
                    return Container(
                      margin: EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      width: double.infinity,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Image.network("${product.thumbnail}"),
                          ),
                          Container(
                            padding: EdgeInsets.all(10),
                            width: double.infinity,
                            child: Text(
                              "${product.title}",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(18),
                            width: double.infinity,
                            child: Text(
                              "Price : \$${product.price}",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(18),
                            width: double.infinity,
                            child: Text(
                              "Discount : ${product.discountPercentage}",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(18),
                            width: double.infinity,
                            child: Text(
                              "${product.description}",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
