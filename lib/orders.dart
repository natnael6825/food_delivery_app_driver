import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage package

import 'deliverydetils.dart';

class OrderPage extends StatefulWidget {
  final int deliveryAgentId;

  const OrderPage({required this.deliveryAgentId});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final FlutterSecureStorage _storage = FlutterSecureStorage(); // Create instance of FlutterSecureStorage

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final url = Uri.parse('https://700f-196-189-17-92.ngrok-free.app/deliveryAgent/getcurrentorders');

    try {
      // Retrieve the token from secure storage
      String? token = await _storage.read(key: 'token');
      
      if (token == null) {
        setState(() {
          _errorMessage = 'Authorization token not found';
          _isLoading = false;
        });
        return;
      }

      // Make the API call with the token in the Authorization header
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Use the token from secure storage
        },
        body: jsonEncode({
          'deliveryAgentId': widget.deliveryAgentId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orders = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load orders';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true; // Show loading indicator during refresh
    });
    await _fetchOrders(); // Re-fetch orders when pulled down
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Current Orders'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : RefreshIndicator(
                  onRefresh: _refreshOrders, // Add refresh functionality here
                  child: ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final orderData = _orders[index];
                      final order = orderData['order'];

                      // Check if 'restaurant' exists and is not null
                      final restaurant = order != null && order.containsKey('restaurant') ? order['restaurant'] : null;

                      return Card(
                        margin: EdgeInsets.all(10),
                        child: ListTile(
                          leading: restaurant != null && restaurant['image'] != null
                              ? Image.network(
                                  restaurant['image'], // Use the image URL directly from the API response
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset('assets/placeholder.png', width: 50, height: 50, fit: BoxFit.cover);
                                  },
                                )
                              : Image.asset('assets/4.png', width: 50, height: 50, fit: BoxFit.cover),
                          title: Text('Order ID: ${order['id']}'),
                          subtitle: Text(restaurant != null ? 'Restaurant: ${restaurant['name']}' : 'Restaurant info not available'),
                          trailing: Text('\$${order['totalPrice']}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeliveryDetils(
                                  order: order,
                                  restaurant: restaurant,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
