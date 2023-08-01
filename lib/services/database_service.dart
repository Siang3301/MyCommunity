import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;
import 'package:mycommunity/services/firebase_file.dart';

class DatabaseService {
  final String uid;
  static String username ='';
  static String phone ='';
  static String bio = '';
  DatabaseService({ required this.uid });

  final CollectionReference usersData = FirebaseFirestore.instance.collection('users_data');
  List<String> defaultPreferences = [
    'Aid & Community',
    'Animal Welfare',
    'Art & Culture',
    'Children & Youth',
    'Education & Lectures',
    'Disabilities',
    'Environment',
    'Food & Hunger',
    'Health & Medical',
    'Technology',
    'Skill-based Volunteering',
  ];

  Future updateUserData(String username, String email, String age, String ic, String contact,
                        String address, String postal, String city, String state, String uid, String usertype, String imageUrl) async {
    return await usersData.doc(uid).set({
      'uid' : uid,
      'username' : username,
      'email' : email,
      'age' : age,
      'identification_number' : ic,
      'contact' : contact,
      'address' : address,
      'postal' : postal,
      'city' : city,
      'state' : state,
      'usertype' : usertype,
      'imageUrl' : imageUrl,
      'preferences': defaultPreferences,
    });
    }

  Future updateOrgData(String orgType, String orgName, String email, String orgID, String contact,
      String address, String postal, String city, String state, String uid, String usertype, String imageUrl) async {
    return await usersData.doc(uid).set({
      'uid' : uid,
      'organisation_type' : orgType,
      'organisation_name' : orgName,
      'email' : email,
      'organisation_ID' : orgID,
      'contact' : contact,
      'address' : address,
      'postal' : postal,
      'city' : city,
      'state' : state,
      'usertype' : usertype,
      'imageUrl' : imageUrl,
    });
  }

  Stream<QuerySnapshot> get users{
    return usersData.snapshots();
  }

  Future getCurrentUserData() async{
    try {
      DocumentSnapshot value = await usersData.doc(uid).get();
      username = value.get('username');
      phone = value.get('phone');
      bio = value.get('bio');
    }catch(e){
      // ignore: avoid_print
      print(e.toString());
      return null;
    }
  }

  Future uploadProfilePicToFirebase(BuildContext context, File imageFile) async {
    String fileName = FirebaseAuth.instance.currentUser!.uid;
    Reference firebaseStorageRef =
    FirebaseStorage.instance.ref().child('users/ProfilePicture/$fileName');
    UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    taskSnapshot.ref.getDownloadURL().then(
          // ignore: avoid_print
          (value) => print("Done: $value"),
    );
  }

  static UploadTask? uploadFileForTask(List<File> file, String projectID, String taskID){
    try {
      for (int i = 0; i< file.length; i++) {
        final ref = FirebaseStorage.instance.ref().child('projects/$projectID/$taskID/${Path.basename(file[i].path)}');
        ref.putFile(file[i]);
        if(file[i] == file.last){
          return ref.putFile(file[i]);
        }
      }

    } on FirebaseException {
      return null;
    }
    return null;
  }

  static UploadTask? uploadBytes(String destination, Uint8List data) {
    try {
      final ref = FirebaseStorage.instance.ref(destination);

      return ref.putData(data);
    } on FirebaseException {
      return null;
    }
  }

  static Future<List<String>> _getDownloadLinks(List<Reference> refs) =>
      Future.wait(refs.map((ref) => ref.getDownloadURL()).toList());

  static Future<List<FirebaseFile>> listAll(String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    final result = await ref.listAll();

    final urls = await _getDownloadLinks(result.items);

    return urls
        .asMap()
        .map((index, url) {
      final ref = result.items[index];
      final name = ref.name;
      final file = FirebaseFile(ref: ref, name: name, url: url);

      return MapEntry(index, file);
    })
        .values
        .toList();
  }

}