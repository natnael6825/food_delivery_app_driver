import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'map_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'orderdetilpage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<dynamic> orders = [];
  bool isLoading = true;
  bool isAcceptingOrder = false; // State to track the loading for accepting order
  bool noOrdersFound = false; // State to track if no orders were found
  final FlutterSecureStorage _storage = FlutterSecureStorage(); // Secure storage for token

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

  // Method to handle logout in case of token error
  Future<void> _logout() async {
    await _storage.delete(key: 'token'); // Delete the token from secure storage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    ); // Navigate back to the login page
  }

  Future<void> fetchOrders(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://e6e4-196-189-16-22.ngrok-free.app/deliveryAgent/nearbyorders');

    try {
      // Retrieve the token from secure storage
      String? token = await _storage.read(key: 'token');

      final response = await http.post(
        url,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send the token in the header
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['orders'];
        setState(() {
          orders = data;
          isLoading = false;
          noOrdersFound = data.isEmpty;
        });
      } else if (response.statusCode == 401) {
        // Token is invalid or expired, logout the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired, please log in again')),
        );
        _logout();
      } else if (response.statusCode == 404) {
        final body = jsonDecode(response.body);
        if (body['message'] == "No confirmed orders found" ||
            body['message'] == "No nearby unaccepted orders found") {
          setState(() {
            noOrdersFound = true;
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
      noOrdersFound = false; // Reset the noOrdersFound flag during refresh
    });
    await _getCurrentLocationAndFetchOrders();
  }

  Future<void> acceptOrder(int orderId) async {
    setState(() {
      isAcceptingOrder = true; // Start loading when accepting an order
    });

    final url = Uri.parse(
        'https://e6e4-196-189-16-22.ngrok-free.app/deliveryAgent/acceptorder');
    try {
      // Retrieve the token from secure storage
      String? token = await _storage.read(key: 'token');

      final response = await http.post(
        url,
        body: jsonEncode({
          'orderId': orderId,
          'deliveryAgentId': 1, // Replace with actual deliveryAgentId
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send the token in the header
        },
      );

      setState(() {
        isAcceptingOrder = false; // Stop loading after response
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order accepted successfully')),
        );
        _refreshOrders();
      } else if (response.statusCode == 401) {
        // Token is invalid or expired, logout the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired, please log in again')),
        );
        _logout();
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
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshOrders, // Handle pull-to-refresh
                  child: noOrdersFound
                      ? ListView(
                          // Wrapping with ListView to allow pull-to-refresh on empty view
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.8, // Adjust height so message is centered
                              child: Center(
                                child: Text(
                                  'No orders nearby, refresh again in a while.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final restaurant = order['restaurant'];
                            final imageUrl =
                                restaurant['image']; // Get image from the restaurant object

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
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 8.0),
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
          if (isAcceptingOrder)
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
