import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentend/activity/ViewPostDetailsActivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesActivity extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesActivity> {
  bool _isLoading = true;
  List<DocumentSnapshot> _favoritePosts = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('email', isEqualTo: email)
          .get();

      List<DocumentSnapshot> posts = [];
      for (var doc in favoritesSnapshot.docs) {
        var postId = doc['post_id'];
        DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get();
        if (postSnapshot.exists) {
          posts.add(postSnapshot);
        }
      }

      setState(() {
        _favoritePosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching favorite posts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching favorite posts. Please try again.'),
        ),
      );
    }
  }

  Future<void> _removeFavorite(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    if (email.isEmpty) return;

    try {
      var favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('email', isEqualTo: email)
          .where('post_id', isEqualTo: postId)
          .get();

      if (favoritesSnapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('favorites')
            .doc(favoritesSnapshot.docs.first.id)
            .delete();

        // Remove the post from the list and reload the page
        setState(() {
          _favoritePosts.removeWhere((post) => post.id == postId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post removed from favorites.'),
          ),
        );
      }
    } catch (e) {
      print("Error removing favorite post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error removing post from favorites. Please try again.'),
        ),
      );
    }
  }

  void _showRemoveConfirmationDialog(String postId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove Favorite'),
          content:
              Text('Are you sure you want to remove this post from favorites?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _removeFavorite(postId);
                // Reload the favorites list
                _fetchFavorites();
              },
              child: Text('Remove'),
              //   style: TextButton.styleFrom(
              //     primary: Colors.red,
              //   ),
            ),
          ],
        );
      },
    );
  }

  void _viewPostDetails(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPostDetailsActivity(
          docId: postId,
          favourite: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favoritePosts.isEmpty
              ? Center(child: Text('No favorite posts yet.'))
              : ListView.builder(
                  itemCount: _favoritePosts.length,
                  itemBuilder: (context, index) {
                    var post =
                        _favoritePosts[index].data() as Map<String, dynamic>;
                    var postId = _favoritePosts[index].id;
                    var imageUrls = post['imageUrls'] ?? [];
                    var rent = post['details']['rent'] ?? 'N/A';
                    var area = post['address']['area'] ?? 'N/A';
                    var description = post['description'] ?? 'N/A';

                    return Card(
                      child: Column(
                        children: [
                          // Post images carousel
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 150,
                              enableInfiniteScroll: false,
                              enlargeCenterPage: true,
                            ),
                            items: imageUrls
                                .map<Widget>((url) => Image.network(url))
                                .toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rent: $rent',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Area: $area'),
                                Text('Description: $description'),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => _viewPostDetails(postId),
                                      child: Text('View Details'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          _showRemoveConfirmationDialog(postId),
                                      child: Text('Remove'),
                                      //   style: TextButton.styleFrom(
                                      //     primary: Colors.red,
                                      //   ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
