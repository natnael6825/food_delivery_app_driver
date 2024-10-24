import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage package

import 'deliverydetils.dart';
import 'login.dart';

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
    _fetchOrders(); // Fetch orders on page load
  }

  // Method to handle logout in case of token error
  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'token'); // Delete the token from secure storage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    ); // Navigate back to the login page
  }

  // Fetch orders for the delivery agent
  Future<void> _fetchOrders() async {
    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/deliveryAgent/getcurrentorders');

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

      print(response.body);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody is Map<String, dynamic> &&
            responseBody.containsKey('message') &&
            responseBody['message'] == 'No current delivering orders found for this delivery agent') {
          setState(() {
            _errorMessage = 'No accepted orders';
            _isLoading = false;
            _orders = [];
          });
        } else {
          setState(() {
            _orders = responseBody;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Token is invalid or expired, logout the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired, please log in again')),
        );
        _logout(context);
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

  // Refresh the order list by re-fetching orders
  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true; // Show loading indicator during refresh
    });
    await _fetchOrders(); // Re-fetch orders when pulled down
  }

void _navigateToDeliveryDetails(
  BuildContext context,
  dynamic order,
  dynamic restaurant,
) async {
  // Ensure latitude and longitude are not null and are converted to double
  final double? deliveryLatitude = order['latitude'] != null
      ? double.tryParse(order['latitude'].toString())
      : null;
  final double? deliveryLongitude = order['longitude'] != null
      ? double.tryParse(order['longitude'].toString())
      : null;

  if (deliveryLatitude == null || deliveryLongitude == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid delivery location')),
    );
    return;
  }

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DeliveryDetails(
        order: order,
        restaurant: restaurant,
        deliveryLatitude: deliveryLatitude, // Pass the converted latitude
        deliveryLongitude: deliveryLongitude, // Pass the converted longitude
      ),
    ),
  );

  if (result == true) {
    _refreshOrders(); // Refresh the orders after confirming an order
  }
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

                      final restaurant = order != null && order.containsKey('restaurant')
                          ? order['restaurant']
                          : null;

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
                                    return Image.asset('assets/placeholder.png',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover);
                                  },
                                )
                              : Image.asset('assets/4.png',
                                  width: 50, height: 50, fit: BoxFit.cover),
                          title: Text('Order ID: ${order['id']}'),
                          subtitle: Text(restaurant != null
                              ? 'Restaurant: ${restaurant['name']}'
                              : 'Restaurant info not available'),
                          trailing: Text('\$${order['totalPrice'].toStringAsFixed(2)}'),
                          onTap: () {
                            _navigateToDeliveryDetails(context, order, restaurant); // Navigate to delivery details page
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
