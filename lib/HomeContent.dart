import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_screen.dart';
import 'package:geolocator/geolocator.dart';

import 'orderdetilpage.dart';

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<dynamic> orders = [];
  bool isLoading = true;
  bool isAcceptingOrder = false; // Add a state to track the loading for accept order

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchOrders();
  }

  Future<void> _getCurrentLocationAndFetchOrders() async {
    try {
      Position position = await _determinePosition();
      fetchOrders(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> fetchOrders(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://700f-196-189-17-92.ngrok-free.app/deliveryAgent/nearbyorders'); // Replace with your API URL

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['orders'];
        setState(() {
          orders = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders')),
        );
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      isLoading = true;
    });
    await _getCurrentLocationAndFetchOrders();
  }

  Future<void> acceptOrder(int orderId) async {
    setState(() {
      isAcceptingOrder = true; // Start loading when accepting an order
    });

    final url = Uri.parse(
        'https://700f-196-189-17-92.ngrok-free.app/deliveryAgent/acceptorder');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'orderId': orderId,
          'deliveryAgentId': 1, // Replace with actual deliveryAgentId
        }),
        headers: {'Content-Type': 'application/json'},
      );

      setState(() {
        isAcceptingOrder = false; // Stop loading after response
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order accepted successfully')),
        );
        _refreshOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept order: ${response.body}')),
        );
      }
    } catch (error) {
      setState(() {
        isAcceptingOrder = false; // Stop loading after error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  void _showOrderDetails(dynamic order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF652023),
        automaticallyImplyLeading: false,
        title: Text('Available Orders'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_location),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack( // Use Stack to overlay the loading spinner on top of the content
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final restaurant = order['restaurant'];
                      final imageUrl = restaurant['image']; // Get image from the restaurant object

                      return GestureDetector(
                        onTap: () => _showOrderDetails(order),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  imageUrl,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                        'assets/placeholder.png',
                                        height: 120,
                                        fit: BoxFit.cover,
                                        width: double.infinity);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    restaurant['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF652023),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () => acceptOrder(order['id']),
                                    child: Text('Accept Order'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          if (isAcceptingOrder) // Show loading animation if isAcceptingOrder is true
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Image.asset(
                  'assets/Pizza_spinning.gif', // Use your pizza spinning gif
                  width: 100,
                  height: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
