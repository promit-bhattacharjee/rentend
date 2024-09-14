import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentend/Components/DefaultSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPostActivity extends StatefulWidget {
  final String? postId;

  EditPostActivity({this.postId});

  @override
  _EditPostActivityState createState() => _EditPostActivityState();
}

class _EditPostActivityState extends State<EditPostActivity> {
  final _formKey = GlobalKey<FormState>();
  String? _userEmail;
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
  List<String> _images = [];
  String _religion = '';
  bool _isLoading = false;
  List<String> _oldImageUrls = [];
  List<String> religions = [];
  List<String> areas = [];
  String _selectedArea = '';

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    fetchAreas();
    fetchReligions();
    if (widget.postId != null) {
      _loadPostData(widget.postId!);
    }
  }

  Future<void> selectImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles != null &&
          pickedFiles.length >= 1 &&
          pickedFiles.length <= 5) {
        setState(() {
          _images = pickedFiles.map((file) => file.path).toList();
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
    setState(() {
      _isLoading = true; // Show spinner while fetching data
    });

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
    } finally {
      setState(() {
        _isLoading = false; // Hide spinner after operation
      });
    }
  }

  void fetchReligions() async {
    setState(() {
      _isLoading = true; // Show spinner while fetching data
    });

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
    } finally {
      setState(() {
        _isLoading = false; // Hide spinner after operation
      });
    }
  }

  Future<String> _uploadImage(String imagePath) async {
    try {
      final File image = File(imagePath);
      final mimeTypeMap = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'bmp': 'image/bmp',
        'webp': 'image/webp',
      };

      String fileExtension = imagePath.split('.').last.toLowerCase();
      String? mimeType = mimeTypeMap[fileExtension];
      if (mimeType == null) {
        throw Exception('Unsupported file type');
      }

      String fileName =
          '${Random().nextInt(1000)}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
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

    if (_images.isEmpty && _oldImageUrls.isEmpty) {
      DefaultSnackbar.AlertSnackBar(
          "Please select at least one image.", context);
      return;
    }

    setState(() {
      _isLoading = true; // Show spinner
    });

    List<String> imageUrls = [];
    try {
      // Upload new images
      for (String imagePath in _images) {
        String imageUrl = await _uploadImage(imagePath);
        if (imageUrl.isEmpty) {
          throw Exception('Image upload failed');
        }
        imageUrls.add(imageUrl);
      }

      // Combine old and new image URLs
      imageUrls.addAll(_oldImageUrls);

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
      Map<String, dynamic> postData = {
        'address': address,
        'email': _userEmail,
        'details': details,
        'imageUrls': imageUrls,
        'parking': {
          'bike': _hasBikeParking,
          'car': _hasCarParking,
        },
        'description': _description,
        'status': 'updated',
        'religion': _religion,
        'updated_at': Timestamp.now(),
      };

      if (widget.postId == null) {
        await FirebaseFirestore.instance.collection('posts').add(postData);
        DefaultSnackbar.SuccessSnackBar("Listing Created", context);
      } else {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update(postData);
        DefaultSnackbar.SuccessSnackBar("Listing Updated", context);
        Navigator.pop(context);
      }
    } catch (e) {
      DefaultSnackbar.AlertSnackBar(e.toString(), context);
    } finally {
      _formKey.currentState!.reset();
      setState(() {
        _images.clear();
        _oldImageUrls.clear();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPostData(String postId) async {
    setState(() {
      _isLoading = true; // Show spinner while loading data
    });

    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _block = data['address']['block'] ?? '';
          _roadNumber = data['address']['roadNumber'] ?? '';
          _houseNumber = data['address']['houseNumber'] ?? '';
          _userEmail = data['email'] as String?;
          _rent = data['details']['rent'] ?? '';
          _squareFeet = data['details']['squareFeet'] ?? '';
          _floor = data['address']['floor'] ?? '';
          _bedroom = int.parse(data['details']['bedroom'] ?? '1');
          _washroom = int.parse(data['details']['washroom'] ?? '0');
          _dining = int.parse(data['details']['dining'] ?? '0');
          _drawing = int.parse(data['details']['drawing'] ?? '0');
          _balcony = int.parse(data['details']['balcony'] ?? '0');
          _hasBikeParking = data['parking']['bike'] ?? false;
          _hasCarParking = data['parking']['car'] ?? false;
          _description = data['description'] ?? '';
          _religion = data['religion'] ?? "";
          _selectedArea = data['address']['area'] ?? "";
          _oldImageUrls = List<String>.from(data['imageUrls'] ?? []);
        });
      }
    } catch (e) {
      DefaultSnackbar.AlertSnackBar(
          "Error loading post data: " + e.toString(), context);
    } finally {
      setState(() {
        _isLoading = false; // Hide spinner after data is loaded
      });
    }
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email');
    });
  }

  void _confirmAndDeleteImage(String imageUrl) async {
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Delete'),
              content: Text('Are you sure you want to delete this image?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirm) {
      setState(() {
        _oldImageUrls.remove(imageUrl);
      });

      try {
        String fileName = imageUrl.split('/').last;
        await FirebaseStorage.instance.ref().child('posts/$fileName').delete();
        DefaultSnackbar.SuccessSnackBar("Image deleted successfully", context);
      } catch (e) {
        DefaultSnackbar.AlertSnackBar(
            "Error deleting image: " + e.toString(), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.postId == null ? 'Create Post' : 'Edit Post'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator()) // Show spinner when loading
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      initialValue: _rent,
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _rent = value!,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter rent' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Block'),
                      initialValue: _block,
                      onSaved: (value) => _block = value!,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter block' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Road Number'),
                      initialValue: _roadNumber,
                      onSaved: (value) => _roadNumber = value!,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter road number' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'House Number'),
                      initialValue: _houseNumber,
                      onSaved: (value) => _houseNumber = value!,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter house number' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Square Feet'),
                      initialValue: _squareFeet,
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _squareFeet = value!,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter square feet' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Floor'),
                      initialValue: _floor,
                      onSaved: (value) => _floor = value!,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter floor' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Bedroom'),
                      initialValue: _bedroom.toString(),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _bedroom = int.parse(value!),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter number of bedrooms'
                          : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Washroom'),
                      initialValue: _washroom.toString(),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _washroom = int.parse(value!),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter number of washrooms'
                          : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Dining'),
                      initialValue: _dining.toString(),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _dining = int.parse(value!),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter number of dining spaces'
                          : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Drawing'),
                      initialValue: _drawing.toString(),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _drawing = int.parse(value!),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter number of drawing rooms'
                          : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Balcony'),
                      initialValue: _balcony.toString(),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _balcony = int.parse(value!),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter number of balconies'
                          : null,
                    ),
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
                        SizedBox(width: 20),
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
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Description'),
                      initialValue: _description,
                      maxLines: 5,
                      onSaved: (value) => _description = value!,
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: selectImages,
                      child: Text('Select Images'),
                    ),
                    SizedBox(height: 16.0),
                    _images.isNotEmpty
                        ? Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _images.map((path) {
                              return Stack(
                                children: [
                                  Image.file(
                                    File(path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () {
                                        setState(() {
                                          _images.remove(path);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          )
                        : SizedBox.shrink(),
                    _oldImageUrls.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Existing Images:',
                              ),
                              SizedBox(height: 8.0),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _oldImageUrls.map((url) {
                                  return Stack(
                                    children: [
                                      Image.network(
                                        url,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        right: 0,
                                        child: IconButton(
                                          icon: Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () =>
                                              _confirmAndDeleteImage(url),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
    );
  }
}
