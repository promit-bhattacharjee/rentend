import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentListActivity extends StatefulWidget {
  @override
  _AppointmentListActivityState createState() =>
      _AppointmentListActivityState();
}

class _AppointmentListActivityState extends State<AppointmentListActivity> {
  bool _showAppointments = true;
  bool _isLoading = true;
  List<DocumentSnapshot> _appointments = [];
  List<DocumentSnapshot> _requests = [];
  Map<String, Map<String, dynamic>> _posts = {}; // Cache for post data

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _fetchRequests();
  }

  Future<List<DocumentSnapshot>> _fetchData(
      String collection, String field, String email) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where(field, isEqualTo: email)
          .get();
      return snapshot.docs;
    } catch (e) {
      print("Error fetching data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data. Please try again.')),
      );
      return [];
    }
  }

  Future<void> _fetchAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _appointments = await _fetchData('appointments', 'renter_email', email);
    for (var doc in _appointments) {
      var data = doc.data() as Map<String, dynamic>;
      await _fetchPostData(data['post_id']);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _requests = await _fetchData('appointments', 'seeker_email', email);
    for (var doc in _requests) {
      var data = doc.data() as Map<String, dynamic>;
      await _fetchPostData(data['post_id']);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPostData(String postId) async {
    try {
      DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      if (postSnapshot.exists) {
        var postData = postSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _posts[postId] = postData;
        });
      }
    } catch (e) {
      print("Error fetching post data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching post data. Please try again.')),
      );
    }
  }

  Future<String?> getMobileNumber(String userEmail) async {
    try {
      // Reference to the Firestore users collection
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      // Query Firestore to find the document with the given email
      QuerySnapshot querySnapshot =
          await users.where('email', isEqualTo: userEmail).get();

      // Check if a user was found
      if (querySnapshot.docs.isNotEmpty) {
        // Assuming there's only one document with the matching email
        var userDoc = querySnapshot.docs.first;

        // Get the mobile number field
        String mobileNumber = userDoc['mobile'] as String;

        return mobileNumber;
      } else {
        print('No user found with this email.');
        return null;
      }
    } catch (e) {
      print('Error fetching mobile number: $e');
      return null;
    }
  }

  Future<void> _rescheduleAppointment(DocumentSnapshot appointment) async {
    var data = appointment.data() as Map<String, dynamic>;
    var currentAppointmentTime =
        (data['appointment_time'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime newAppointmentTime = currentAppointmentTime;
        TextEditingController numberController =
            TextEditingController(); // Controller for the number input

        return AlertDialog(
          title: Text('Reschedule Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select new appointment time:'),
              SizedBox(height: 10),
              DateTimeField(
                format: DateFormat('yyyy-MM-dd HH:mm'),
                initialValue: newAppointmentTime,
                onChanged: (date) {
                  newAppointmentTime = date ?? newAppointmentTime;
                },
                onShowPicker: (context, currentValue) async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    initialDate: currentValue ?? newAppointmentTime,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                          currentValue ?? newAppointmentTime),
                    );
                    return DateTimeField.combine(date, time);
                  } else {
                    return currentValue;
                  }
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter your contact number',
                  hintText: 'e.g. 1234567890',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                var contactNumber = numberController.text;
                if (contactNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a contact number.')),
                  );
                  return;
                }
                try {
                  await FirebaseFirestore.instance
                      .collection('appointments')
                      .doc(appointment.id)
                      .update({
                    'appointment_time': newAppointmentTime,
                    'accepter_contact': contactNumber,
                  });
                  Navigator.of(context).pop();
                  _fetchAppointments(); // Reload data
                } catch (e) {
                  print("Error rescheduling appointment: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Error rescheduling appointment. Please try again.')),
                  );
                }
              },
              child: Text('Reschedule'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptAppointment(DocumentSnapshot appointment) async {
    var data = appointment.data() as Map<String, dynamic>;
    var seekerEmail = data['seeker_email'] as String;

    // Fetch the mobile number of the seeker
    String? mobileNumber = await getMobileNumber(seekerEmail);

    if (mobileNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mobile number not found for this user.')),
      );
      return;
    }

    // Show confirmation modal before accepting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Accept Appointment'),
          content: Text('Are you sure you want to accept this appointment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('appointments')
                      .doc(appointment.id)
                      .update({
                    'status': 'accepted',
                    'accepter_contact': mobileNumber,
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Appointment accepted successfully!')),
                  );
                  _fetchAppointments(); // Reload data
                } catch (e) {
                  print("Error accepting appointment: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Error accepting appointment. Please try again.')),
                  );
                }
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelAppointment(DocumentSnapshot appointment) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Appointment'),
          content: Text('Are you sure you want to cancel this appointment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('appointments')
                      .doc(appointment.id)
                      .delete();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Appointment cancelled successfully!')),
                  );
                  _fetchAppointments(); // Reload data
                } catch (e) {
                  print("Error canceling appointment: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Error canceling appointment. Please try again.')),
                  );
                }
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointments & Requests'),
      ),
      body: Column(
        children: [
          ToggleButtons(
            isSelected: [_showAppointments, !_showAppointments],
            onPressed: (index) {
              setState(() {
                _showAppointments = index == 0;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('My Appointments'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('My Requests'),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _showAppointments
                        ? _appointments.length
                        : _requests.length,
                    itemBuilder: (context, index) {
                      var appointment = _showAppointments
                          ? _appointments[index]
                          : _requests[index];
                      var data = appointment.data() as Map<String, dynamic>;
                      var appointmentTime =
                          (data['appointment_time'] as Timestamp).toDate();
                      var postId = data['post_id'];
                      var postData = _posts[postId] ?? {};
                      var imageUrls = postData['imageUrls'] ?? [];
                      var rent = postData['details']['rent'] ?? 'N/A';
                      var area = postData['address']['area'] ?? 'N/A';
                      var description = postData['description'] ?? 'N/A';

                      return Card(
                        margin: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            imageUrls.isNotEmpty
                                ? CarouselSlider.builder(
                                    itemCount: imageUrls.length,
                                    itemBuilder: (context, index, realIndex) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image:
                                                NetworkImage(imageUrls[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                    options: CarouselOptions(
                                      height: 200,
                                      enlargeCenterPage: true,
                                      enableInfiniteScroll: true,
                                    ),
                                  )
                                : Container(
                                    height: 200,
                                    color: Colors.grey,
                                    child: Center(
                                        child: Text('No Images Available')),
                                  ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rent: \$${rent.toString()}',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Area: ${area.toString()}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Description: $description',
                                    style: TextStyle(fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Appointment Time: ${DateFormat('yyyy-MM-dd HH:mm').format(appointmentTime)}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 10),
                                  if (_showAppointments) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            _acceptAppointment(appointment);
                                          },
                                          child: Text('Accept'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _rescheduleAppointment(appointment);
                                          },
                                          child: Text('Reschedule'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _cancelAppointment(appointment);
                                          },
                                          child: Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
