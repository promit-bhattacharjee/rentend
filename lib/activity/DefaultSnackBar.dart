import 'package:flutter/material.dart';

class DefaultSnackbar {
  DefaultSnackbar(String code, BuildContext context);

 static AlertSnackBar(message, context) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Center(child:  Text(message),),backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),)
    );
  }
  static SuccessSnackBar(message, context) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Center(child:  Text(message),),backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),)
    );
  }
}
