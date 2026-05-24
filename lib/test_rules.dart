import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final email = 'test_rules_${DateTime.now().millisecondsSinceEpoch}@test.com';
  final password = 'password123';
  
  try {
    print('Signing up...');
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    print('Signed up with UID: $uid');
    
    await Future.delayed(Duration(seconds: 2));
    
    // Test 1: Full map (with legacyUserId and approvalStatus)
    try {
      print('Test 1: Full map');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'phoneNumber': null,
        'displayName': null,
        'photoUrl': null,
        'bloodGroup': null,
        'legacyUserId': '1234',
        'role': 'user',
        'approvalStatus': 'pending',
      });
      print('Test 1 SUCCEEDED!');
    } catch (e) {
      print('Test 1 FAILED: $e');
    }
    
    // Test 2: Original map (without legacyUserId and approvalStatus)
    try {
      print('Test 2: Original map');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'phoneNumber': null,
        'displayName': null,
        'photoUrl': null,
        'bloodGroup': null,
        'role': 'user',
      });
      print('Test 2 SUCCEEDED!');
    } catch (e) {
      print('Test 2 FAILED: $e');
    }
    
    // Test 3: Minimal map
    try {
      print('Test 3: Minimal map');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
      });
      print('Test 3 SUCCEEDED!');
    } catch (e) {
      print('Test 3 FAILED: $e');
    }

    print('DONE.');
  } catch (e) {
    print('Auth failed: $e');
  }
}
