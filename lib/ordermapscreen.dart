import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';

class OrderMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double restaurantLatitude;
  final double restaurantLongitude;
  final String address;

  const OrderMapScreen({
    required this.latitude,
    required this.longitude,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
    required this.address,
  });

  @override
  _OrderMapScreenState createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  late GoogleMapController mapController;
  Set<Polyline> _polylines = {};
  LatLng? _driverLocation;

  @override
  void initState() {
    super.initState();
    _getDriverLocation();
  }

  Future<void> _getDriverLocation() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    setState(() {
      _driverLocation = LatLng(_locationData.latitude!, _locationData.longitude!);
    });

    _drawRoute();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_driverLocation != null) {
      _drawRoute();
    }
  }

  Future<void> _drawRoute() async {
    final origin = '${widget.restaurantLatitude},${widget.restaurantLongitude}';
    final destination = '${widget.latitude},${widget.longitude}';
    final apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final points = data['routes'][0]['overview_polyline']['points'];
        final List<LatLng> polylineCoordinates = _decodePolyline(points);

        setState(() {
          _polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ));
        });
      } else {
        print('Error: ${data['status']}');
      }
    } catch (e) {
      print('Error fetching directions: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng position = LatLng((lat / 1E5), (lng / 1E5));
      polylineCoordinates.add(position);
    }

    return polylineCoordinates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Location'),
        backgroundColor: const Color(0xFF652023),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.restaurantLatitude, widget.restaurantLongitude),
          zoom: 13.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('restaurant'),
            position: LatLng(widget.restaurantLatitude, widget.restaurantLongitude),
            infoWindow: InfoWindow(
              title: 'Restaurant',
              snippet: 'Restaurant Location',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),  // Explicitly set to red
          ),
          Marker(
            markerId: MarkerId('orderLocation'),
            position: LatLng(widget.latitude, widget.longitude),
            infoWindow: InfoWindow(
              title: 'Delivery Address',
              snippet: widget.address,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),  // Explicitly set to green
          ),
          if (_driverLocation != null)
            Marker(
              markerId: MarkerId('driverLocation'),
              position: _driverLocation!,
              infoWindow: InfoWindow(
                title: 'Your Location',
                snippet: 'Driver\'s Current Location',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),  // Explicitly set to blue
            ),
        },
        polylines: _polylines,
      ),
    );
  }
}
