import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'video_streaming_page.dart';

class DeliveryDetils extends StatelessWidget {
  final dynamic order;
  final dynamic restaurant;

  const DeliveryDetils({required this.order, this.restaurant});

  // Method to mark order as completed by making a POST request
  Future<void> _completeOrder(BuildContext context, String orderId) async {
    final url = Uri.parse('https://700f-196-189-17-92.ngrok-free.app/orders/compltedorder');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'orderId': orderId, // Sending the orderId in the request body
        }),
      );

      if (response.statusCode == 200) {
        // Show success message and navigate back or show a dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order marked as completed')));
        Navigator.pop(context); // Go back to the previous screen
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete order')));
      }
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${order['id']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Quantity: ${order['quantity']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Total Price: \$${order['totalPrice']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Delivery Address: ${order['address']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Status: ${order['status']}',
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            SizedBox(height: 16),
            restaurant != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restaurant: ${restaurant['name']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      restaurant['image'] != null
                          ? Image.network(
                              'https://700f-196-189-17-92.ngrok-free.app${restaurant['image']}',
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('assets/4.png', height: 200, fit: BoxFit.cover);
                              },
                            )
                          : Image.asset('assets/4.png', height: 200, fit: BoxFit.cover),
                      SizedBox(height: 8),
                      Text(
                        'Restaurant Address: ${restaurant['streetName'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                : Text(
                    'Restaurant info not available',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Handle tracking functionality here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Background color
              ),
              child: Text('Allow Tracking'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoStreamingPage(orderId: order['id'].toString()), // Pass the orderId to the video streaming page
                  ),
                );
              },
              child: Text('Allow Video Tracking'),
            ),
            SizedBox(height: 16),
            // Button to mark the order as completed
            ElevatedButton(
              onPressed: () {
                _completeOrder(context, order['id'].toString()); // Call the complete order function
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Background color for completion
              ),
              child: Text('Complete Delivery'),
            ),
          ],
        ),
      ),
    );
  }
}
