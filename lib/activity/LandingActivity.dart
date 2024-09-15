import 'package:flutter/material.dart';
import 'package:rentend/Components/AuthAppBar.dart';
import 'package:rentend/Components/DefaultSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingActivity extends StatefulWidget {
  @override
  _LandingActivityState createState() => _LandingActivityState();
}

class _LandingActivityState extends State<LandingActivity> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? isLoggedIn = prefs.getBool('user') ?? false;

    if (isLoggedIn == true) {
      final String email = prefs.getString('email') ?? '';
      DefaultSnackbar.SuccessSnackBar("Successfully Logged In", context);
      // Navigate to the home page or any other route after successful login
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(
            context, "/homePage"); // Change to your home screen route
      });
    } else {
      // Navigate to login if not logged in
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, "/loginPage");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AuthAppBar(),
      body: Center(
        child:
            CircularProgressIndicator(), // You can show a loader while checking login status
      ),
    );
  }
}
