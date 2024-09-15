import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentend/Components/AuthAppBar.dart';
import 'package:rentend/Components/DefaultSnackBar.dart';
import 'package:rentend/main.dart';

class SignupActivity extends StatefulWidget {
  const SignupActivity({Key? key}) : super(key: key);

  @override
  _SignupActivityState createState() => _SignupActivityState();
}

class _SignupActivityState extends State<SignupActivity> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchAreas(); // Fetch areas when the widget initializes
  }

  List<String> areas = []; // List to store areas fetched from Firestore

  void fetchAreas() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('areas').get();

      List<String> areasList = [];
      querySnapshot.docs.forEach((doc) {
        List<dynamic> areaValues = doc.get('area');
        areasList = areaValues.cast<String>();
      });
      setState(() {
        areas = areasList;
      });
    } catch (e) {
      print('Error fetching areas: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> createUser() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user?.uid)
          .set({
        'name': _nameController.text,
        'email': email,
        'mobile': _mobileController.text,
        'area': _areaController.text,
      });

      DefaultSnackbar.SuccessSnackBar("UserModel.dart Created", context);
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginActivity()),
        );
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AuthAppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: "Mobile",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: DropdownButtonFormField<String>(
                onChanged: (String? newValue) {
                  setState(() {
                    _areaController.text = newValue!;
                  });
                },
                items: areas.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: "Area",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: () async {
                        await createUser();
                      },
                      child: Text("Submit"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(100, 50),
                      ),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.all(10),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Login"),
                          style: TextButton.styleFrom(
                            minimumSize: Size(50, 50),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
