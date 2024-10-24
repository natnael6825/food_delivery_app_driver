import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // Geolocator to get the current location
import 'login.dart';
import 'video_streaming_page.dart';

class DeliveryDetails extends StatefulWidget {
  final dynamic order;
  final dynamic restaurant;
  final double deliveryLatitude;
  final double deliveryLongitude;

  const DeliveryDetails({
    required this.order,
    required this.restaurant,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
  });

  @override
  _DeliveryDetailsState createState() => _DeliveryDetailsState();
}

class _DeliveryDetailsState extends State<DeliveryDetails> {
  String? menuImageUrl;
  bool isLoadingMenu = true;
  bool isCompletingOrder = false; // Track if the order is being completed
  bool isLoadingVideoTracking = false; // Track loading for video tracking status
  final FlutterSecureStorage _storage = FlutterSecureStorage(); // Secure storage for token

  Timer? _locationUpdateTimer; // Timer to update location
  bool _isUpdatingLocation = false; // Track if location updates are running
  Color _locationButtonColor = Colors.green; // Button color for location updates

  @override
  void initState() {
    super.initState();
    fetchMenuDetails();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Method to handle logout in case of token error
  Future<void> _logout() async {
    await _storage.delete(key: 'token');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  // Fetch menu details by menuId
  Future<void> fetchMenuDetails() async {
    final menuId = widget.order['menuId'];
    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/deliveryAgent/menudetils?menuId=$menuId');

    try {
      String? token = await _storage.read(key: 'token');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print(response.body + "-----");

      if (response.statusCode == 200) {
        final menuData = jsonDecode(response.body);
        setState(() {
          menuImageUrl = menuData['image'];
          isLoadingMenu = false;
        });
      } else if (response.statusCode == 401) {
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

  // Method to open Google Maps and show the delivery location
  Future<void> _openDeliveryLocationInMaps() async {
    final double latitude = widget.deliveryLatitude;
    final double longitude = widget.deliveryLongitude;

    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the map.')),
      );
    }
  }

  // Method to update the delivery agent's location every 15 seconds
  void _toggleLocationUpdates() {
    if (_isUpdatingLocation) {
      _locationUpdateTimer?.cancel(); // Stop updating location
      setState(() {
        _isUpdatingLocation = false;
        _locationButtonColor = Colors.green; // Change button color to green
      });
    } else {
      // Start updating location every 15 seconds
      _locationUpdateTimer = Timer.periodic(Duration(seconds: 15), (Timer timer) async {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _updateLocation(position.latitude, position.longitude);
      });

      setState(() {
        _isUpdatingLocation = true;
        _locationButtonColor = Colors.red; // Change button color to red
      });
    }
  }

  // Method to send location update to the backend
  Future<void> _updateLocation(double latitude, double longitude) async {
    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/deliveryAgent/updateLocation');

    
    try {
      String? token = await _storage.read(key: 'token');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      if (response.statusCode == 200) {
        print('Location updated successfully');
      } else {
        print('Failed to update location');
      }
    } catch (error) {
      print('Error updating location: $error');
    }
  }

  // Method to mark order as completed
  Future<void> _completeOrder(BuildContext context, String orderId) async {
    setState(() {
      isCompletingOrder = true;
    });

    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/orders/completedOrder');
    try {
      String? token = await _storage.read(key: 'token');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order marked as completed')));
        Navigator.pop(context, true); // Pass true to refresh
        _locationUpdateTimer?.cancel(); // Stop location updates when order is completed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete order')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred')));
    } finally {
      setState(() {
        isCompletingOrder = false;
      });
    }
  }






Future<void> _updateOrderStatusToDelivering(String orderId) async {
    setState(() {
      isLoadingVideoTracking = true; // Start loading for video tracking
    });

    final url = Uri.parse('https://food-delivery-backend-uls4.onrender.com/orders/updateStatus');
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
          'newStatus': 'delivering', // Set the new status to 'delivering'
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to delivering')),
        );
        // Navigate to video tracking page after updating the status
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoStreamingPage(orderId: orderId),
          ),
        );
      } else if (response.statusCode == 401) {
        // Token is invalid or expired, logout the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired, please log in again')),
        );
        _logout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order status')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    } finally {
      setState(() {
        isLoadingVideoTracking = false; // Stop loading for video tracking
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    String orderStatus = widget.order['status'].toString().trim().toLowerCase();
    bool isDeliveryOngoing = orderStatus == 'delivering' || orderStatus == 'delivery man received';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Return true when back is pressed
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Order Details'),
          backgroundColor: const Color(0xFF652023),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
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

                  // Buttons for Location Tracking, Video Tracking, and Completing Delivery
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

                  if (isCompletingOrder) // Show a loading progress bar when completing order
                    Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),

            // Show loading screen when updating to 'delivering'
            if (isLoadingVideoTracking)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
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
      return SizedBox.shrink();
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
                        return SizedBox.shrink();
                      },
                    )
                  : SizedBox.shrink(),
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
      // Toggle Location Updates button placed on top
      ElevatedButton.icon(
        icon: Icon(Icons.location_on),
        label: Text('Toggle Location Updates'),
        onPressed: _toggleLocationUpdates, // Toggle location updates
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50),
          backgroundColor: _locationButtonColor, // Button color changes based on location updates
        ),
      ),
      SizedBox(height: 16), // Spacing between the buttons

      // Row for See Delivery Location and Allow Video Tracking buttons
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text('See Delivery Location'),
              onPressed: _openDeliveryLocationInMaps,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
            ),
          ),
          SizedBox(width: 8), // Space between the two buttons
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.videocam),
              label: Text('Allow Video Tracking'),
              onPressed: isDeliveryOngoing
                  ? () {
                      _updateOrderStatusToDelivering(widget.order['id'].toString());
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: isDeliveryOngoing ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 16), // Space between the row and the complete button

      // Complete Delivery button
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
