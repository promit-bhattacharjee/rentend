import 'package:flutter/material.dart';

class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize =>
      Size.fromHeight(200.0); // Custom height for the AppBar

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false, // Removes the back button
      // Use the custom height
      title: Center(
        child: Text(
          "Rentend",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.blue, // Customize the background color
      elevation: 0, // Optional: Removes shadow
    );
  }
}
