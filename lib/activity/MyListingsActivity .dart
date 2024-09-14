import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rentend/activity/EditPostActivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyListingsActivity extends StatefulWidget {
  @override
  _MyListingsActivityState createState() => _MyListingsActivityState();
}

class _MyListingsActivityState extends State<MyListingsActivity> {
  bool _isDeleting = false; // Track delete operation state

  @override
  Widget build(BuildContext context) {
    return _isDeleting
        ? Center(
            child: CircularProgressIndicator()) // Show spinner while deleting
        : FutureBuilder<String>(
            future: _getUserEmail(),
            builder: (context, emailSnapshot) {
              if (emailSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (emailSnapshot.hasError) {
                return Center(child: Text('Error: ${emailSnapshot.error}'));
              }

              if (!emailSnapshot.hasData || emailSnapshot.data!.isEmpty) {
                return Center(child: Text('No listings available.'));
              }

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .where('email', isEqualTo: emailSnapshot.data)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No listings available.'));
                  }

                  List<DocumentSnapshot> documents = snapshot.data!.docs;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    padding: EdgeInsets.all(10),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      var data =
                          documents[index].data() as Map<String, dynamic>;

                      // Extract data from Firestore document
                      String description =
                          data['description'] ?? 'No description';
                      List<dynamic> imageUrls = data['imageUrls'] ?? [];
                      String rent = data['details']['rent'] ?? 'Not available';
                      String docId = documents[index].id;

                      return SizedBox(
                        height: 400,
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                                          height: 150,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10),
                                            ),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  imageUrls[index]),
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
                                  : Placeholder(fallbackHeight: 150),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Rent: \$${rent}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Container(
                                height: 50,
                                color: Colors.grey[200],
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditPostActivity(
                                              postId: docId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [Icon(Icons.edit)],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _confirmDelete(docId, imageUrls),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          )
                                        ],
                                      ),
                                      //   style: ElevatedButton.styleFrom(
                                      //     primary: Colors.red,
                                      //   ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
  }

  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  Future<void> _confirmDelete(String docId, List<dynamic> imageUrls) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final firestore = FirebaseFirestore.instance;
        final storage = FirebaseStorage.instance;

        // Delete images from Firebase Storage
        for (var imageUrl in imageUrls) {
          final ref = storage.refFromURL(imageUrl);
          await ref.delete();
        }

        // Delete document from Firestore
        await firestore.collection('posts').doc(docId).delete();

        // Refresh the screen
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post deleted successfully')),
        );
      } catch (e) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }
}
