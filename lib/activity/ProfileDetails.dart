import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentend/Data/Area.dart';
import 'package:rentend/Components/DefaultSnackBar.dart';
import '../Data/UserData.dart';

class ProfileDetails extends StatefulWidget {
  final String email;

  const ProfileDetails({Key? key, required this.email}) : super(key: key);

  @override
  _ProfileDetailsState createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Map<String, dynamic>? userData;
  List<String> areas = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchAreas();
  }

  Future<void> fetchUserData() async {
    try {
      String jsonData = await UserData().getUserData(widget.email);
      setState(() {
        userData = json.decode(jsonData);
        _nameController.text = userData!['name'];
        _mobileController.text = userData!['mobile'];
        _areaController.text = userData!['area'];
        _ageController.text = userData!['age'];
        _religionController.text = userData!['religion'];
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> updateUser() async {
    try {
      if (_passwordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text) {
        User? user = FirebaseAuth.instance.currentUser;
        await user?.updatePassword(_passwordController.text);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userData!['uid'])
          .update({
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'area': _areaController.text,
        'age': _ageController.text,
        'religion': _religionController.text,
      });

      DefaultSnackbar.SuccessSnackBar("Profile Updated Successfully", context);
      await fetchUserData();
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  Future<void> fetchAreas() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('area').get();
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
    _mobileController.dispose();
    _areaController.dispose();
    _ageController.dispose();
    _religionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                        labelText: 'Age', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _religionController,
                    decoration: InputDecoration(
                        labelText: 'Religion', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
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
                      labelText: _areaController.text,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      updateUser();
                    },
                    child: Text('Update Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}
