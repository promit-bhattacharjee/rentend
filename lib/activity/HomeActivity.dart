import 'package:flutter/material.dart';
import 'package:rentend/activity/CreatePost.dart';
import 'package:rentend/activity/UserLogin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentend/activity/ViewPostActivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeActivity extends StatefulWidget {
  final String? userEmail;
  HomeActivity({Key? key, this.userEmail}) : super(key: key);

  @override
  _HomeActivityState createState() => _HomeActivityState();
}

class _HomeActivityState extends State<HomeActivity> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    CreatePost(),

    Viewpostactivity(), // Placeholder for Feed Screen
    Text('My Listings Screen'), // Placeholder for My Listings Screen
    Text('Appointments Screen'), // Placeholder for Appointments Screen
    Text('Favourites Screen'), // Placeholder for Favourites Screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              prefs.setBool('user', false);
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserLogin()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black, // Dark background color
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // Replace with Instagram-like icon
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), // Replace with Instagram-like icon
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline,
                size: 36), // Center icon, larger size
            label: 'Create Post',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(Icons.calendar_today), // Replace with Instagram-like icon
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(Icons.favorite_border), // Replace with Instagram-like icon
            label: 'Favourites',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white, // White color for active icons
        unselectedItemColor:
            Colors.white70, // Slightly faded white for inactive icons
        onTap: _onItemTapped,
        selectedFontSize: 14, // Adjust the font size if needed
        unselectedFontSize: 12, // Adjust the font size if needed
        showUnselectedLabels: true, // Show labels for unselected items
      ),
    );
  }
}
