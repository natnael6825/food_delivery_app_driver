import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Man'),
        backgroundColor: const Color(0xFF652023),
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          FoodRequestPage(),
          AcceptedOrdersPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Accepted Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF652023),
        onTap: _onItemTapped,
      ),
    );
  }
}

class FoodRequestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.all(10),
          child: ListTile(
            leading: Icon(Icons.fastfood, color: const Color(0xFF652023)),
            title: Text('Food Request ${index + 1}'),
            subtitle: Text('Details of the request...'),
            trailing: ElevatedButton(
              onPressed: () {
                // Accept request logic
              },
              child: Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF652023), // background
              ),
            ),
          ),
        );
      },
    );
  }
}

class AcceptedOrdersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Accepted Orders Page'),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Profile Page'),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Delivery App',
    theme: ThemeData(
      primarySwatch: Colors.red,
    ),
    home: HomePage(),
  ));
}
