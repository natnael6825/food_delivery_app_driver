import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ordermapscreen.dart';

class OrderDetailsPage extends StatelessWidget {
  final dynamic order;

  const OrderDetailsPage({required this.order});

  // Function to accept the order
  Future<void> acceptOrder(BuildContext context) async {
    final deliveryAgentId = 1; // Replace with the actual delivery agent ID
    final url = Uri.parse('https://700f-196-189-17-92.ngrok-free.app/deliveryAgent/acceptorder');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN_HERE', // Add authorization if required
        },
        body: jsonEncode({
          'orderId': order['id'],
          'deliveryAgentId': deliveryAgentId,
          'streamingLink': null, // Optional, set this if you have a streaming link
        }),
      );

      if (response.statusCode == 201) {
        // Order accepted successfully, show a confirmation dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Order Accepted'),
              content: Text('The order has been accepted successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Go back to the previous screen
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Handle errors
        print('Failed to accept order: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept order. Please try again.')),
        );
      }
    } catch (error) {
      print('Error accepting order: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = order['restaurant'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.network(
              'https://700f-196-189-17-92.ngrok-free.app${restaurant['image']}',
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/placeholder.png', height: 200, fit: BoxFit.cover);
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
              'Order ID: ${order['id']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Quantity: ${order['quantity']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Total Price: \$${order['totalPrice']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Delivery Address: ${order['address']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Status: ${order['status']}',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderMapScreen(
                      latitude: double.parse(order['latitude']),
                      longitude: double.parse(order['longitude']),
                      restaurantLatitude: restaurant['latitude'],
                      restaurantLongitude: restaurant['longitude'],
                      address: order['address'],
                    ),
                  ),
                );
              },
              child: Text('View on Map'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                acceptOrder(context);
              },
              child: Text('Accept Order'),
            ),
          ],
        ),
      ),
    );
  }
}
