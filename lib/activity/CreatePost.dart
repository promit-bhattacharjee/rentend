import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentend/activity/DefaultSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart'; // For MIME type checking

class CreatePost extends StatefulWidget {
  @override
  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final _formKey = GlobalKey<FormState>();
  String? _userEmail;
  Map<String, String> _address = {};
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

  List<File?> _images = []; // List to store multiple images
  bool _isLoading = false; // Spinner state
  List<String> areas = [];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    fetchAreas();
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
      });
    } catch (e) {
      print('Error fetching areas: $e');
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final mimeType = lookupMimeType(image.path);
      if (mimeType == null || !mimeType.startsWith('image/')) {
        throw Exception('The selected file is not a valid image.');
      }

      String fileExtension = image.path.split('.').last;
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

    _formKey.currentState!.save(); // Save form fields

    if (_images.isEmpty) {
      DefaultSnackbar.AlertSnackBar(
          "Please select at least one image.", context);
      return;
    }

    setState(() {
      _isLoading = true; // Show spinner
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

      Map<String, String> details = {
        'bedroom': _bedroom.toString(),
        'washroom': _washroom.toString(),
        'dining': _dining.toString(),
        'drawing': _drawing.toString(),
        'balcony': _balcony.toString(),
        'squareFeet': _squareFeet,
        'floor': _floor,
        'rent': _rent,
        'block': _block,
        'roadNumber': _roadNumber,
        'houseNumber': _houseNumber,
      };

      await FirebaseFirestore.instance.collection('posts').add({
        'address': _address,
        'email': _userEmail,
        'details': details,
        'imageUrls': imageUrls, // Store list of image URLs
        'parking': {
          'bike': _hasBikeParking,
          'car': _hasCarParking,
        },
        '_description': _description,
        'created_at': Timestamp.now(), // Add created_at timestamp
        'updated_at': Timestamp.now(), // Add updated_at timestamp
      });

      DefaultSnackbar.SuccessSnackBar("Listing Created", context);
    } catch (e) {
      DefaultSnackbar.AlertSnackBar(e.toString(), context);
    } finally {
      _formKey.currentState!.reset();
      setState(() {
        _images.clear();
        _isLoading = false;
      });
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

  void _incrementCounter(String field) {
    setState(() {
      switch (field) {
        case 'bedroom':
          _bedroom++;
          break;
        case 'washroom':
          _washroom++;
          break;
        case 'dining':
          _dining++;
          break;
        case 'drawing':
          _drawing++;
          break;
        case 'balcony':
          _balcony++;
          break;
      }
    });
  }

  void _decrementCounter(String field) {
    setState(() {
      switch (field) {
        case 'bedroom':
          if (_bedroom > 1) _bedroom--;
          break;
        case 'washroom':
          if (_washroom > 0) _washroom--;
          break;
        case 'dining':
          if (_dining > 0) _dining--;
          break;
        case 'drawing':
          if (_drawing > 0) _drawing--;
          break;
        case 'balcony':
          if (_balcony > 0) _balcony--;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Listing'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Image Upload and Preview
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectImages,
                            child: Text('Select Images'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _images.isNotEmpty
                        ? SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Image.file(
                                    _images[index]!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(),

                    // Form Fields
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            onChanged: (String? newValue) {
                              setState(() {
                                _address['area'] = newValue ?? '';
                              });
                            },
                            items: areas
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            decoration:
                                InputDecoration(labelText: 'Select Area'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an area';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Block'),
                            onSaved: (value) {
                              _block = value ?? '';
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration:
                                InputDecoration(labelText: 'Road Number'),
                            onSaved: (value) {
                              _roadNumber = value ?? '';
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration:
                                InputDecoration(labelText: 'House Number'),
                            onSaved: (value) {
                              _houseNumber = value ?? '';
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Rent'),
                            keyboardType: TextInputType.number,
                            onSaved: (value) {
                              _rent = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the rent amount';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration:
                                InputDecoration(labelText: 'Square Feet'),
                            onSaved: (value) {
                              _squareFeet = value ?? '';
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Floor'),
                            onSaved: (value) {
                              _floor = value ?? '';
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: _hasBikeParking,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _hasBikeParking = value ?? false;
                                  });
                                },
                              ),
                              Text('Bike Parking'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: _hasCarParking,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _hasCarParking = value ?? false;
                                  });
                                },
                              ),
                              Text('Car Parking'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCounterRow(
                            'Bedroom',
                            _bedroom,
                            () => _incrementCounter('bedroom'),
                            () => _decrementCounter('bedroom'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildCounterRow(
                            'Washroom',
                            _washroom,
                            () => _incrementCounter('washroom'),
                            () => _decrementCounter('washroom'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCounterRow(
                            'Dining',
                            _dining,
                            () => _incrementCounter('dining'),
                            () => _decrementCounter('dining'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildCounterRow(
                            'Drawing',
                            _drawing,
                            () => _incrementCounter('drawing'),
                            () => _decrementCounter('drawing'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCounterRow(
                            'Balcony',
                            _balcony,
                            () => _incrementCounter('balcony'),
                            () => _decrementCounter('balcony'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration:
                                InputDecoration(labelText: 'Description'),
                            maxLines: 3,
                            onSaved: (value) {
                              _description = value ?? '';
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit'),
                    ),
                    if (_isLoading) Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email');
    });
  }
}
