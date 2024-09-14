import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentend/Components/DefaultSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewPostDetailsActivity extends StatefulWidget {
  final String docId;
  final bool? favourite; // Make this nullable

  ViewPostDetailsActivity({required this.docId, this.favourite}); // Change here

  @override
  _ViewPostDetailsActivityState createState() =>
      _ViewPostDetailsActivityState();
}

class _ViewPostDetailsActivityState extends State<ViewPostDetailsActivity> {
  bool _isLoading = false;
  DateTime? _selectedDateTime;

  Future<void> _bookAppointment(
      String postId, String renterEmail, DateTime appointmentTime) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final seekerEmail = prefs.getString('email') ?? '';

    if (seekerEmail.isEmpty) {
      DefaultSnackbar.AlertSnackBar('Seeker email not available', context);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'post_id': postId,
        'renter_email': renterEmail,
        'seeker_email': seekerEmail,
        'appointment_time': appointmentTime,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
      DefaultSnackbar.SuccessSnackBar(
          'Appointment booked successfully', context);
    } catch (e) {
      DefaultSnackbar.AlertSnackBar('Failed to book appointment: $e', context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToFavorites(String postId) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final seekerEmail = prefs.getString('email') ?? '';

    if (seekerEmail.isEmpty) {
      DefaultSnackbar.AlertSnackBar('Seeker email not available', context);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('favorites').add({
        'post_id': postId,
        'email': seekerEmail,
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
      DefaultSnackbar.SuccessSnackBar('Added to favorites', context);
    } catch (e) {
      DefaultSnackbar.AlertSnackBar('Failed to add to favorites: $e', context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateTime() async {
    DateTime now = DateTime.now();
    DateTime initialDate = now.add(Duration(days: 1));
    DateTime selectedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: now,
          lastDate: DateTime(2100),
        ) ??
        initialDate;

    TimeOfDay selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now),
        ) ??
        TimeOfDay.fromDateTime(now);

    setState(() {
      _selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _showBookingModal(String postId, String renterEmail) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Appointment Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedDateTime != null
                  ? 'Selected time: ${DateFormat('MMMM d, yyyy h:mm a').format(_selectedDateTime!)}'
                  : 'No time selected'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectDateTime,
                child: Text('Select Date & Time'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_selectedDateTime != null) {
                  _bookAppointment(postId, renterEmail, _selectedDateTime!);
                }
              },
              child: Text('Book Appointment'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.docId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No details available.'));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          String description = data['description'] ?? 'No description';
          List<dynamic> imageUrls = data['imageUrls'] ?? [];
          String rent = data['details']['rent'] ?? 'Not available';
          String drawing = data['details']['drawing'] ?? 'Not available';
          String floor = data['address']['floor'] ?? 'Not available';
          String houseNumber =
              data['address']['houseNumber'] ?? 'Not available';
          String roadNumber = data['address']['roadNumber'] ?? 'Not available';
          String squareFeet = data['details']['squareFeet'] ?? 'Not available';
          String washroom = data['details']['washroom'] ?? 'Not available';
          String email = data['email'] ?? 'Not available';
          Map<String, dynamic> parking = data['parking'] ?? {};
          String balcony = data['details']['balcony'] ?? 'Not available';
          String bedroom = data['details']['bedroom'] ?? 'Not available';
          String block = data['details']['block'] ?? 'Not available';
          String dining = data['details']['dining'] ?? 'Not available';

          Timestamp createdAt = data['created_at'];
          Timestamp updatedAt = data['updated_at'];
          String area = data['address']['area'] ?? 'Not available';

          DateFormat dateFormat = DateFormat('MMMM d, yyyy h:mm:ss a');

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carousel for images
                    imageUrls.isNotEmpty
                        ? CarouselSlider.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index, realIndex) {
                              return Container(
                                width: double.infinity,
                                height: 250, // Adjust height as needed
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrls[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                            options: CarouselOptions(
                              height: 250,
                              viewportFraction: 1.0,
                              autoPlay: true,
                            ),
                          )
                        : Placeholder(fallbackHeight: 250),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rent: \$${rent}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Description: $description',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Area: $area\n'
                                'Balcony: $balcony\n'
                                'Bedroom: $bedroom\n'
                                'Block: $block\n'
                                'Dining: $dining\n'
                                'Drawing: $drawing\n'
                                'Floor: $floor\n'
                                'House Number: $houseNumber\n'
                                'Rent: $rent\n'
                                'Road Number: $roadNumber\n'
                                'Square Feet: $squareFeet\n'
                                'Washroom: $washroom\n'
                                'Email: $email\n'
                                'Parking: ${parking['bike'] ? 'Bike ' : ''}${parking['car'] ? 'Car' : ''}\n'
                                'Post Date: ${dateFormat.format(createdAt.toDate())}\n',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _showBookingModal(
                                            widget.docId, email),
                                    child: Text('Book an Appointment'),
                                  ),
                                  widget.favourite == true
                                      ? ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () =>
                                                  _addToFavorites(widget.docId),
                                          child: Icon(Icons.favorite),
                                        )
                                      : Text(""),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}
