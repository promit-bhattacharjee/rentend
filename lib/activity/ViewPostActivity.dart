import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Viewpostactivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Listings'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('posts').get(),
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
              var data = documents[index].data() as Map<String, dynamic>;

              // Extract data from Firestore document
              String description = data['description'] ?? 'No description';
              List<dynamic> imageUrls = data['imageUrls'] ?? [];
              String rent = data['details']['rent'] ?? 'Not available';

              return Card(
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
                                height:
                                    150, // Static height for carousel images
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrls[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                            options: CarouselOptions(
                              height: 150,
                              viewportFraction: 1.0,
                              autoPlay: true,
                            ),
                          )
                        : Placeholder(
                            fallbackHeight: 150,
                          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      height: 100, // Extended bottom of the card
                      color: Colors
                          .grey[200], // Background color for extended area
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Show modal with detailed view
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return ListingDetailsModal(
                                  listingId: documents[index].id,
                                );
                              },
                            );
                          },
                          child: Text('View Details'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ListingDetailsModal extends StatelessWidget {
  final String listingId;

  ListingDetailsModal({required this.listingId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('posts').doc(listingId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('Listing not found.'));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String description = data['description'] ?? 'No description';
        List<dynamic> imageUrls = data['imageUrls'] ?? [];
        String rent = data['details']['rent'] ?? 'Not available';
        String area = data['details']['area'] ?? 'Not specified';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              imageUrls.isNotEmpty
                  ? CarouselSlider.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index, realIndex) {
                        return Container(
                          width: double.infinity,
                          height: 250, // Static height for carousel images
                          decoration: BoxDecoration(
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
                  : Placeholder(
                      fallbackHeight: 250,
                    ),
              SizedBox(height: 16),
              Text(
                'Rent: \$${rent}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Area: ${area}',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
