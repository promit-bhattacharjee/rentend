import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:rentend/activity/ViewPostDetailsActivity.dart';

class ViewPostActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
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

            String area = data['address']['area'] ?? 'Not available';

            //   String drawing = data['details']['drawing'] ?? 'Not available';
            //   String floor = data['details']['floor'] ?? 'Not available';
            //   String houseNumber =
            //       data['details']['houseNumber'] ?? 'Not available';
            //   String roadNumber =
            //       data['details']['roadNumber'] ?? 'Not available';
            //   String squareFeet =
            //       data['details']['squareFeet'] ?? 'Not available';
            //   String washroom = data['details']['washroom'] ?? 'Not available';
            //   String email = data['details']['email'] ?? 'Not available';
            //   Map<String, dynamic> parking = data['details']['parking'] ?? {};

            // Get document ID
            String docId = documents[index].id;

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
                              height: 150, // Static height for carousel images
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
                            height: 230,
                            viewportFraction: 1.0,
                            autoPlay: true,
                          ),
                        )
                      : Placeholder(fallbackHeight: 150),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Rent : \$${rent}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "Area : " + area,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Description : " + description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),

                  Container(
                    height: 50,
                    // color: Colors.grey[200],
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          print(docId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewPostDetailsActivity(
                                docId: docId,
                                favourite: true,
                              ),
                            ),
                          );
                        },
                        child: Text("Details"),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
