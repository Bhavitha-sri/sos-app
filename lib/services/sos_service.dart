import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SosService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> sendSOS({
    required String userName,
    required String location,
    required String alertType,
    required String mapLink,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ??
        (await FirebaseAuth.instance.signInAnonymously()).user!.uid;

    await _db.collection('sos_requests').add({
      'userId': uid,
      'name': userName,
      'location': location,
      'mapLink': mapLink,
      'alertType': alertType,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  static Future<void> sendSafetyCheckIn({
    required String userName,
    required String location,
    required String status,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ??
        (await FirebaseAuth.instance.signInAnonymously()).user!.uid;

    await _db.collection('safety_checkins').add({
      'userId': uid,
      'name': userName,
      'location': location,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
