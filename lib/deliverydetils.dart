import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';
import 'video_streaming_page.dart';

class DeliveryDetails extends StatefulWidget {
  final dynamic order;
  final dynamic restaurant;

  const DeliveryDetails({required this.order, this.restaurant});

  @override
  _DeliveryDetailsState createState() => _DeliveryDetailsState();
}

class _DeliveryDetailsState extends State<DeliveryDetails> {
  String? menuImageUrl;
  bool isLoadingMenu = true;
  final FlutterSecureStorage _storage = FlutterSecureStorage(); // Secure storage for token

  @override
  void initState() {
    super.initState();
    fetchMenuDetails(); // Fetch menu details when the page loads
  }

  // Method to handle logout in case of token error
  Future<void> _logout() async {
    await _storage.delete(key: 'token'); // Delete the token from secure storage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    ); // Navigate back to the login page
  }

  // Fetch menu details by menuId
  Future<void> fetchMenuDetails() async {
    final menuId = widget.order['menuId']; // Get menuId from the order object
    final url = Uri.parse('https://e6e4-196-189-16-22.ngrok-free.app/deliveryAgent/menudetils/$menuId'); // API endpoint to fetch menu details

    try {
      // Retrieve the token from secure storage
      String? token = await _storage.read(key: 'token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Send the token in the header
        },
      );

      if (response.statusCode == 200) {
        final menuData = jsonDecode(response.body);
        setState(() {
          menuImageUrl = menuData['image']; // Get the image from the menu data
          isLoadingMenu = false; // Set loading to false
        });
      } else if (response.statusCode == 401) {
        // Token is invalid or expired, logout the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired, please log in again')),
        );
        _logout();
      } else {
        setState(() {
          menuImageUrl = null;
          isLoadingMenu = false;
        });
      }
    } catch (error) {
      print('Error fetching menu details: $error');
      setState(() {
        menuImageUrl = null;
        isLoadingMenu = false;
      });
    }
  }

  // Method to mark order as completed by making a POST request
  Future<void> _completeOrder(BuildContext context, String orderId) async {
    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/orders/compltedorder');
    try {
      // Retrieve the token from secure storage
      String? token = await _storage.read(key: 'token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send the token in the header
        },
        body: jsonEncode({
          'orderId': orderId, // Sending the orderId in the request body
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order marked as completed')));
        Navigator.pop(context, true); // Pass true as result to trigger refresh
      } else if (response.statusCode == 401) {
        // Token is invalid or expired, logout the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired, please log in again')),
        );
        _logout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete order')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Order status: ${widget.order['status']}');

    // Check if order status is either 'delivering' or 'delivery man received'
    String orderStatus = widget.order['status'].toString().trim().toLowerCase();
    bool isDeliveryOngoing = orderStatus == 'delivering' || orderStatus == 'delivery man received';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Return true when back is pressed
        return false; // Prevent the default pop behavior (handled above)
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Order Details'),
          backgroundColor: const Color(0xFF652023),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderInfoSection(),

              _buildRestaurantInfoSection(),

              SizedBox(height: 24),

              // Display the Menu Image
              _buildMenuImageSection(),

              SizedBox(height: 24),

              // Buttons for Map Tracking, Video Tracking, and Completing Delivery
              _buildActionButtons(context, isDeliveryOngoing),

              if (!isDeliveryOngoing)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: Text(
                      'Waiting for restaurant food confirmation.',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for displaying menu image
  Widget _buildMenuImageSection() {
    if (isLoadingMenu) {
      return Center(child: CircularProgressIndicator());
    } else if (menuImageUrl != null) {
      return Image.network(menuImageUrl!, height: 200, fit: BoxFit.cover);
    } else {
      return SizedBox.shrink(); // No image if not found
    }
  }

  // Widget for displaying order information
  Widget _buildOrderInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order ID: ${widget.order['id']}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          'Status: ${widget.order['status']}',
          style: TextStyle(fontSize: 16, color: Colors.green),
        ),
      ],
    );
  }

  // Widget for displaying restaurant information
  Widget _buildRestaurantInfoSection() {
    return widget.restaurant != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              Text(
                'Restaurant: ${widget.restaurant['name']}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              widget.restaurant['image'] != null
                  ? Image.network(
                      widget.restaurant['image'],
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox.shrink(); // Hide image if it fails
                      },
                    )
                  : SizedBox.shrink(), // No fallback image
              SizedBox(height: 8),
              Text(
                'Restaurant Address: ${widget.restaurant['streetName'] ?? 'N/A'}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          )
        : Text(
            'Restaurant info not available',
            style: TextStyle(fontSize: 16, color: Colors.red),
          );
  }

  // Widget for displaying action buttons
  Widget _buildActionButtons(BuildContext context, bool isDeliveryOngoing) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.map),
          label: Text('Track on Map'),
          onPressed: isDeliveryOngoing
              ? () {
                  // Track on map logic
                }
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            backgroundColor: isDeliveryOngoing ? Colors.blue : Colors.grey,
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.videocam),
          label: Text('Allow Video Tracking'),
          onPressed: isDeliveryOngoing
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoStreamingPage(orderId: widget.order['id'].toString()),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            backgroundColor: isDeliveryOngoing ? Colors.blue : Colors.grey,
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.check_circle),
          label: Text('Complete Delivery'),
          onPressed: isDeliveryOngoing
              ? () {
                  _completeOrder(context, widget.order['id'].toString());
                }
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            backgroundColor: isDeliveryOngoing ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
