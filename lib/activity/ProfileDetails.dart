import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentend/Components/DefaultSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Data/UserData.dart';

class ProfileDetails extends StatefulWidget {
  const ProfileDetails({
    Key? key,
  }) : super(key: key);

  @override
  _ProfileDetailsState createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  Map<String, dynamic>? userData;
  List<String> areas = [];
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchAreas();
  }

  Future<void> fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      String jsonData = await UserData().getUserData(email);
      setState(() {
        userData = json.decode(jsonData);
        _nameController.text = userData!['name'];
        _mobileController.text = userData!['mobile'];
        _selectedArea = userData!['area']; // Set the selected area
        _areaController.text = _selectedArea ?? '';
      });
    } catch (e) {
      print('Error fetching user data: $e');
      DefaultSnackbar.AlertSnackBar("Failed to fetch user data", context);
    }
  }

  Future<void> updateUser() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userData!['uid'])
          .update({
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'area': _selectedArea, // Use the selected area
      });

      DefaultSnackbar.SuccessSnackBar("Profile Updated Successfully", context);
      await fetchUserData();
    } catch (e) {
      print('Error updating user data: $e');
      DefaultSnackbar.AlertSnackBar("Failed to update profile", context);
    }
  }

  Future<void> fetchAreas() async {
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
        if (areas.isNotEmpty) {
          _selectedArea = areas[0]; // Set default selected area
        }
      });
    } catch (e) {
      print('Error fetching areas: $e');
      DefaultSnackbar.AlertSnackBar("Failed to fetch areas", context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();

    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Details'),
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: 'Name', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _mobileController,
                    decoration: InputDecoration(
                        labelText: 'Mobile', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedArea = newValue;
                        _areaController.text = newValue ?? '';
                      });
                    },
                    items: areas.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Area',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          updateUser();
                        },
                        child: Text('Update Profile'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/ChangePassword");
                        },
                        child: Text('Reset Password'),
                      )
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
