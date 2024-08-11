import 'package:flutter/material.dart';
import 'package:food_delivery_app_driver/home.dart';
import 'custom_shape_painter.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double triangleHeight = screenHeight * 0.3;
    double rectangleHeight = screenHeight * 0.12;

    return Scaffold(
      body: Stack(
        children: [
          // Custom shape background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(screenWidth, triangleHeight + rectangleHeight),
              painter: CustomShapePainter(
                color: const Color(0xFF652023),
                triangleHeightFactor: 0.6, // Adjust the triangle height factor as needed
              ),
            ),
          ),
          // Login text over the triangle
          Positioned(
            top: triangleHeight, // Adjust position as needed
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: triangleHeight / 7, // Adjust position as needed
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/burger.png', // Update with your image asset
                height: 150,
              ),
            ),
          ),
          // Login form and burger image
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: triangleHeight), // Add space for the triangle part
                  const SizedBox(height: 100),
                  // Username / E-mail TextField
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Username / E-mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password TextField
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Forgot password text
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Forgot password logic
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Color(0xFF652023)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Login button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF652023), // Background color
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Sign Up button
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
