import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rentend/activity/ChangePasswordActivity.dart';
import 'package:rentend/activity/CreatePost.dart';
import 'package:rentend/activity/LandingActivity.dart';
import 'package:rentend/activity/PrivacyPolicyActivity.dart';
import 'package:rentend/activity/ViewPostActivity.dart';
import 'package:rentend/firebase_options.dart';
import 'package:rentend/layout/HomeActivity.dart';
import 'activity/UserLogin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/landingPage',
      routes: {
        '/loginPage': (context) => UserLogin(),
        '/CreatePost': (context) => CreatePostActivity(),
        '/ViewPost': (context) => ViewPostActivity(),
        '/ChangePassword': (context) => ChangePasswordActivity(),
        '/homePage': (context) => HomeActivity(),
        '/landingPage': (context) => LandingActivity(),
        '/PrivacyPolicyPage': (context) => PrivacyPolicyActivity()

        // '/about': (context) => AboutScreen(),
        // '/contact': (context) => ContactScreen(),
      },
      home: const Scaffold(
        body: LoginActivity(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginActivity extends StatelessWidget {
  const LoginActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return UserLogin();
  }
}
