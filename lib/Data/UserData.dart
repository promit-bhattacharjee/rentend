// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// class Userdata{
//
//   Future<String> getUserData(email) async {
//     var userEmail = email;
//     try {
//       FirebaseFirestore firestore = FirebaseFirestore.instance;
//       var querySnapshot = await firestore.collection('users')
//           .where("email", isEqualTo: userEmail)
//           .get();
//       final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
//       if(allData[0].isNotEmpty)
//         {
//           return jsonEncode(allData[0]).toString();
//         }
//       else{
//         return "false";
//       }
//     } catch (e) {
//       print('Error: $e');
//       return "false";
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
class UserData {
  Future<String> getUserData(String email) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;
        Map<String, dynamic> user = userDoc.data() as Map<String, dynamic>;
        user['uid'] = userDoc.id; // Add UID to user data
        return json.encode(user); // Convert the map to a JSON string
      } else {
        return ('No user found with the given email.');
      }
    } catch (e) {
      return ('Error fetching user data: $e');
    }
  }
}
