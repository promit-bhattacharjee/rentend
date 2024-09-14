import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:rentend/Components/DefaultSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePostActivity extends StatefulWidget {
  @override
  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePostActivity> {
  final _formKey = GlobalKey<FormState>();
  String? _userEmail;
  String _selectedArea = '';
  String _rent = '';
  String _block = '';
  String _roadNumber = '';
  String _houseNumber = '';
  int _bedroom = 1;
  int _washroom = 0;
  int _dining = 0;
  int _drawing = 0;
  int _balcony = 0;
  String _squareFeet = '';
  String _floor = '';
  bool _hasBikeParking = false;
  bool _hasCarParking = false;
  String _description = '';
  String _religion = '';

  List<File?> _images = [];
  bool _isLoading = false;
  List<String> areas = [];
  List<String> religions = [
    // 'Hindu',
    // 'Muslim',
    // 'Christian',
    // 'Buddhist',
    // 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    fetchAreas();
    fetchReligions();
  }

  Future selectImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles != null &&
          pickedFiles.length >= 1 &&
          pickedFiles.length <= 5) {
        setState(() {
          _images = pickedFiles.map((file) => File(file.path)).toList();
        });
      } else {
        DefaultSnackbar.AlertSnackBar("Select 1 to 5 images only.", context);
      }
    } catch (e) {
      DefaultSnackbar.AlertSnackBar(
          "Image selection error: " + e.toString(), context);
    }
  }

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
        if (areas.isNotEmpty) {
          _selectedArea = areas[0]; // Set default selected area
        }
      });
    } catch (e) {
      print('Error fetching areas: $e');
    }
  }

  void fetchReligions() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('religions').get();
      List<String> religionsList = [];
      querySnapshot.docs.forEach((doc) {
        List<dynamic> religionValues = doc.get('religions');
        religionsList = religionValues.cast<String>();
      });
      setState(() {
        religions = religionsList;
      });
    } catch (e) {
      print('Error fetching religions: $e');
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      String fileExtension = image.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        throw Exception('The selected file is not a valid image.');
      }

      String fileName = Random().nextInt(1000).toString() +
          DateTime.now().millisecondsSinceEpoch.toString() +
          '.' +
          fileExtension;
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child('posts/$fileName')
          .putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      DefaultSnackbar.AlertSnackBar(
          "Image upload error: " + e.toString(), context);
      return '';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      DefaultSnackbar.AlertSnackBar(
          "Please fill in all required fields.", context);
      return;
    }

    _formKey.currentState!.save();

    if (_images.isEmpty) {
      DefaultSnackbar.AlertSnackBar(
          "Please select at least one image.", context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<String> imageUrls = [];
    try {
      for (File? image in _images) {
        if (image != null) {
          String imageUrl = await _uploadImage(image);
          if (imageUrl.isEmpty) {
            throw Exception('Image upload failed');
          }
          imageUrls.add(imageUrl);
        }
      }

      Map<String, dynamic> address = {
        'area': _selectedArea,
        'floor': _floor,
        'block': _block,
        'roadNumber': _roadNumber,
        'houseNumber': _houseNumber,
      };

      Map<String, String> details = {
        'rent': _rent,
        'bedroom': _bedroom.toString(),
        'washroom': _washroom.toString(),
        'dining': _dining.toString(),
        'drawing': _drawing.toString(),
        'balcony': _balcony.toString(),
        'squareFeet': _squareFeet,
      };

      await FirebaseFirestore.instance.collection('posts').add({
        'address': address,
        'email': _userEmail,
        'details': details,
        'imageUrls': imageUrls,
        'parking': {
          'bike': _hasBikeParking,
          'car': _hasCarParking,
        },
        'description': _description,
        'status': 'created',
        'religion': _religion,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      DefaultSnackbar.SuccessSnackBar("Listing Created", context);
    } catch (e) {
      DefaultSnackbar.AlertSnackBar(e.toString(), context);
    } finally {
      setState(() {
        _images.clear();
        _isLoading = false;
      });
      _formKey.currentState!.reset();
    }
  }

  Widget _buildCounterRow(
      String label, int value, Function increment, Function decrement) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () => decrement(),
            ),
            Text(value.toString()),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => increment(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Select Images
              ElevatedButton(
                onPressed: selectImages,
                child: Text('Select Images'),
              ),
              if (_images.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _images.map((image) {
                    return Image.file(
                      image!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    );
                  }).toList(),
                ),
              // Address Fields
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Area'),
                value: _selectedArea.isNotEmpty ? _selectedArea : null,
                items: areas
                    .map((area) => DropdownMenuItem(
                          value: area,
                          child: Text(area),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArea = value!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Religion'),
                value: _religion.isNotEmpty ? _religion : null,
                items: religions
                    .map((religion) => DropdownMenuItem(
                          value: religion,
                          child: Text(religion),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _religion = value!;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Rent'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _rent = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the rent' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Block'),
                onSaved: (value) => _block = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Road Number'),
                onSaved: (value) => _roadNumber = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'House Number'),
                onSaved: (value) => _houseNumber = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Floor'),
                onSaved: (value) => _floor = value!,
              ),
              // Counter Rows
              _buildCounterRow(
                'Bedroom',
                _bedroom,
                () => setState(() => _bedroom++),
                () => setState(() => _bedroom > 1 ? _bedroom-- : _bedroom),
              ),
              _buildCounterRow(
                'Washroom',
                _washroom,
                () => setState(() => _washroom++),
                () => setState(() => _washroom > 0 ? _washroom-- : _washroom),
              ),
              _buildCounterRow(
                'Dining',
                _dining,
                () => setState(() => _dining++),
                () => setState(() => _dining > 0 ? _dining-- : _dining),
              ),
              _buildCounterRow(
                'Drawing',
                _drawing,
                () => setState(() => _drawing++),
                () => setState(() => _drawing > 0 ? _drawing-- : _drawing),
              ),
              _buildCounterRow(
                'Balcony',
                _balcony,
                () => setState(() => _balcony++),
                () => setState(() => _balcony > 0 ? _balcony-- : _balcony),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Square Feet'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _squareFeet = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value!,
              ),
              // Parking Checkboxes
              Row(
                children: [
                  Checkbox(
                    value: _hasBikeParking,
                    onChanged: (value) {
                      setState(() {
                        _hasBikeParking = value!;
                      });
                    },
                  ),
                  Text('Bike Parking'),
                  Checkbox(
                    value: _hasCarParking,
                    onChanged: (value) {
                      setState(() {
                        _hasCarParking = value!;
                      });
                    },
                  ),
                  Text('Car Parking'),
                ],
              ),
              // Religion Dropdown

              // Submit Button
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Submit'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email') ?? '';
    });
  }
}
