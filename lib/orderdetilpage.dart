import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';
import 'ordermapscreen.dart';

class OrderDetailsPage extends StatefulWidget {
  final dynamic order;

  const OrderDetailsPage({required this.order});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage(); // Secure storage for token
  bool isAcceptingOrder = false; // Add a flag to track the order acceptance status

  // Function to handle logout in case of token error
  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'token'); // Delete the token from secure storage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    ); // Navigate back to the login page
  }

  // Function to accept the order
  Future<void> acceptOrder(BuildContext context) async {
    setState(() {
      isAcceptingOrder = true; // Start showing the loading indicator
    });

    final deliveryAgentId = 1; // Replace with the actual delivery agent ID
    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/deliveryAgent/acceptorder');

    try {
      // Retrieve the token from secure storage
      String? token = await _storage.read(key: 'token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add token in the authorization header
        },
        body: jsonEncode({
          'orderId': widget.order['id'],
          'deliveryAgentId': deliveryAgentId,
          'streamingLink': null, // Optional, set this if you have a streaming link
        }),
      );

      setState(() {
        isAcceptingOrder = false; // Stop showing the loading indicator
      });

      if (response.statusCode == 201) {
        // Order accepted successfully, pop back to HomeContent with true as the result
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order accepted successfully')));
        Navigator.pop(context, true); // Pass true to indicate success
      } else if (response.statusCode == 401) {
        // Token is invalid or expired, logout the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired, please log in again')),
        );
        _logout(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept order. Please try again.')),
        );
      }
    } catch (error) {
      setState(() {
        isAcceptingOrder = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.order['restaurant'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Display the restaurant image from the response directly
                Image.network(
                  restaurant['image'], // Use the restaurant's image URL directly
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/placeholder.png',
                      height: 200,
                      fit: BoxFit.cover,
                    ); // Fallback image in case of error
                  },
                ),
                SizedBox(height: 16),
                Text(
                  restaurant['name'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF652023),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Order ID: ${widget.order['id']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Quantity: ${widget.order['quantity']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Total Price: \$${widget.order['totalPrice']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Delivery Address: ${widget.order['address']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Status: ${widget.order['status']}',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderMapScreen(
                          latitude: double.parse(widget.order['latitude']),
                          longitude: double.parse(widget.order['longitude']),
                          restaurantLatitude: restaurant['latitude'],
                          restaurantLongitude: restaurant['longitude'],
                          address: widget.order['address'],
                        ),
                      ),
                    );
                  },
                  child: Text('View on Map'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    acceptOrder(context); // Start accepting the order
                  },
                  child: Text('Accept Order'),
                ),
              ],
            ),
          ),
          // Show loading progress bar while accepting the order
          if (isAcceptingOrder)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent background
              child: Center(
                child: CircularProgressIndicator(), // Show loading indicator
              ),
            ),
        ],
      ),
    );
  }
}
