import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String address;
  final String email;
  final Map<String, String> details;
  final List<String> imageUrls; // Ensure this is included
  final Map<String, bool> parking;
  final String description;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Post({
    required this.address,
    required this.email,
    required this.details,
    required this.imageUrls,
    required this.parking,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      address: map['address'] ?? 'Not available',
      email: map['email'] ?? 'Not available',
      details: Map<String, String>.from(map['details'] ?? {}),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      parking: Map<String, bool>.from(map['parking'] ?? {}),
      description: map['description'] ?? 'No description',
      createdAt: map['created_at'] ?? Timestamp.now(),
      updatedAt: map['updated_at'] ?? Timestamp.now(),
    );
  }
}
