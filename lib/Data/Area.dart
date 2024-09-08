import 'package:cloud_firestore/cloud_firestore.dart';

class Area {
  Future<List<String>> getAreaMethod() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('area').get();
      List<String> areasList = [];
      querySnapshot.docs.forEach((doc) {
        List<dynamic> areaValues = doc.get('area');
        areasList.addAll(areaValues.cast<String>());
      });
      return areasList;
    } catch (e) {
      return ['null'];
    }
  }
}
