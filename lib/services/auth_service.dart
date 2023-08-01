import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycommunity/initial_screens/signup/organisation/components/body_3.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/body_2.dart';
import 'package:mycommunity/initial_screens/signup/signup_screen.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mycommunity/services/geofencing_service.dart';

class AuthService {

  // 1  --Variable--
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn googleSignIn = GoogleSignIn();

  // 2
  Stream<String?> get onAuthStateChanged =>
      _firebaseAuth.authStateChanges().map((User? user) => user?.uid);

  String getCurrentUID() {
    return (_firebaseAuth.currentUser!).uid;
  }

  // GET CURRENT USER
  Future getCurrentUser() async {
    return _firebaseAuth.currentUser!;
  }

  // 3
  Future<User?> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch(e) {
      print(e.message);
    }
    return null;
  }

  // 4
  Future<String?> signUpUserWithEmailAndPassword({required String email, required String password, required String name, required String age,
                                              required String ic, required String contact, required String address, required String postal,
                                              required String city, required String state, required String usertype}) async {
      try {
        bool isRegister = await isPersonalEmailRegistered(email);
        if(isRegister == true) {
          UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
          _firebaseAuth.currentUser!.updateDisplayName(name);

          //Get user from the result if sign up is successful
          User? user = result.user;
          user?.updateDisplayName(name);
          user?.updatePhotoURL("null");

          await DatabaseService(uid: user!.uid).updateUserData(name, email, age, ic, contact, address, postal, city, state, user.uid, usertype, "");
          user.sendEmailVerification();
          return "Signed up";
      }
      else{
        Fluttertoast.showToast(
          backgroundColor: Colors.grey,
          msg: "The email is registered, please use another email.",
          gravity: ToastGravity.CENTER,
          fontSize: 16.0,
        );
      }
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
    return null;
  }

  // 5
  Future<String?> signUpOrgWithEmailAndPassword({required String email, required String password, required String orgType, required String orgName,
    required String orgID, required String contact, required String address, required String postal,
    required String city, required String state, required String usertype}) async {
    try {
      bool isRegister = await isPersonalEmailRegistered(email);
      if(isRegister == true) {
        UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
        _firebaseAuth.currentUser!.updateDisplayName(orgName);

        //Get user from the result if sign up is successful
        User? user = result.user;
        user?.updateDisplayName(orgName);
        user?.updatePhotoURL("null");

        await DatabaseService(uid: user!.uid).updateOrgData(orgType, orgName, email, orgID, contact, address, postal, city, state, user.uid, usertype, "");
        user.sendEmailVerification();
        return "Signed up";
      }
      else{
        Fluttertoast.showToast(
          backgroundColor: Colors.grey,
          msg: "The email is registered, please use another email.",
          gravity: ToastGravity.CENTER,
          fontSize: 16.0,
        );

      }
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
    return null;
  }

  //Checking user availability
  Future<bool> isPersonalEmailRegistered(String email) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('users_data')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    final List<DocumentSnapshot> documents = result.docs;
    if (documents.isNotEmpty) {
      return false;
    } else {
      print('Email validated and can be used');
    }
      return true;
  }

  // 5
  Future<String?> signOut() async {
    try {
      await _firebaseAuth.signOut();
      currentIndex = 0;
      return "Signed out";
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
  }

// 6
  User? getUser() {
    try {
      return _firebaseAuth.currentUser;
    } on FirebaseAuthException {
      return null;
    }
  }

  Future<User?> signUpWithGoogle_personal({required BuildContext context}) async {

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    googleSignIn.disconnect();

    final GoogleSignInAccount? googleSignInAccount =
    await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {

        final UserCredential userCredential =
        await auth.signInWithCredential(credential);
        user = userCredential.user;

        final snapShot = await FirebaseFirestore.instance
            .collection('users_data')
            .doc(user!.uid) // varuId in your case
            .get();

        // ignore: unnecessary_null_comparison
        if (snapShot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar(
              content:
              'The google account already exists. Please try the other accounts.',
            ),
          );
          googleSignIn.disconnect();
          auth.signOut();
          return null;
        }else{
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar2(
              content:
              'Please sign up your personal details before log in to Mycommunity.',
            ),
          );
          initialRouteIncrement++;
          String name = user.displayName!;
          String email = user.email!;
          String password = " ";
          String option = "google";
          Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalSignupBody_2(name: name, email: email, password: password, option: option)));
          auth.signOut();
          return null;
        }

      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar(
              content:
              'The account already exists with a different credential.',
            ),
          );
        } else if (e.code == 'invalid-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar(
              content:
              'Error occurred while accessing credentials. Try again.',
            ),
          );
          googleSignIn.disconnect();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          AuthService.customSnackBar(
            content: 'Error occurred using Google Sign-In. Try again.',
          ),
        );
      }
      return user;
    }
    return null;
  }

  Future<User?> signUpWithGoogle_organisation({required BuildContext context, required String orgType, required String orgName}) async {

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    googleSignIn.disconnect();

    final GoogleSignInAccount? googleSignInAccount =
    await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {

        final UserCredential userCredential =
        await auth.signInWithCredential(credential);
        user = userCredential.user;

        final snapShot = await FirebaseFirestore.instance
            .collection('users_data')
            .doc(user!.uid) // varuId in your case
            .get();

        // ignore: unnecessary_null_comparison
        if (snapShot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar(
              content:
              'The google account already exists. Please try the other accounts.',
            ),
          );
          googleSignIn.disconnect();
          auth.signOut();
          return null;
        }else{
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar2(
              content:
              'Please sign up your organisation details before log in to Mycommunity.',
            ),
          );
          initialRouteIncrement++;
          String email = user.email!;
          String password = " ";
          String option = "google";
          Navigator.push(context, MaterialPageRoute(builder: (context) => OrganisationSignupBody_3(orgName: orgName, orgType: orgType, email: email, password: password, option: option)));
          auth.signOut();
          return null;
        }

      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar(
              content:
              'The account already exists with a different credential.',
            ),
          );
        } else if (e.code == 'invalid-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar(
              content:
              'Error occurred while accessing credentials. Try again.',
            ),
          );
          googleSignIn.disconnect();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          AuthService.customSnackBar(
            content: 'Error occurred using Google Sign-In. Try again.',
          ),
        );
      }
      return user;
    }
    return null;
  }

  Future<User?> signInWithGoogle({required BuildContext context}) async {

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;
    googleSignIn.disconnect();

    final GoogleSignInAccount? googleSignInAccount =
    await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {

        final UserCredential userCredential =
        await auth.signInWithCredential(credential);
        user = userCredential.user;

        final snapShot = await FirebaseFirestore.instance
            .collection('users_data')
            .doc(user!.uid) // varuId in your case
            .get();

        // ignore: unnecessary_null_comparison
        if (snapShot == null || !snapShot.exists)  {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar2(
              content:
              'Please create a new personal account before log in to Mycommunity.',
            ),
          );
          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
          await user.delete();
          auth.signOut();
          googleSignIn.disconnect();
          return null;
        }else{
          return user;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar(
              content:
              'The account already exists with a different credential.',
            ),
          );
        } else if (e.code == 'invalid-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            AuthService.customSnackBar(
              content:
              'Error occurred while accessing credentials. Try again.',
            ),
          );
          googleSignIn.disconnect();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          AuthService.customSnackBar(
            content: 'Error occurred using Google Sign-In. Try again.',
          ),
        );
      }

    }
    return null;
  }

  Future<String?> signUpUserWithGoogle({required String email, required String name, required String age,
    required String ic, required String contact, required String address, required String postal,
    required String city, required String state, required String usertype}) async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance; User? user;
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken, idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential = await auth.signInWithCredential(credential);
        user = userCredential.user;
        user?.updatePhotoURL(googleSignInAccount.photoUrl);
        user?.updateDisplayName(name);
        String imageurl = googleSignInAccount.photoUrl.toString();
        final snapShot = await FirebaseFirestore.instance
            .collection('users_data')
            .doc(user!.uid)
            .get();
        if (snapShot == null || !snapShot.exists) {
          await DatabaseService(uid: user.uid).updateUserData(
              name, email, age, ic, contact, address, postal, city, state, user.uid, usertype, imageurl
          );
        }
        return "Signed up";
      }else{
        user!.delete();
      }
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
    return null;
  }

  Future<String?> signUpOrgWithGoogle({required String orgType, required String orgName, required String email,
    required String orgID, required String contact, required String address, required String postal,
    required String city, required String state, required String usertype}) async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user;

      final GoogleSignInAccount? googleSignInAccount =
      await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential =
        await auth.signInWithCredential(credential);
        user = userCredential.user;

        user?.updateDisplayName(orgName);
        user?.updatePhotoURL(googleSignInAccount.photoUrl);
        String imageurl = googleSignInAccount.photoUrl.toString();
        //get user data from firestore
        final snapShot = await FirebaseFirestore.instance
            .collection('users_data')
            .doc(user!.uid) // varuId in your case
            .get();

        // ignore: unnecessary_null_comparison
        if (snapShot == null || !snapShot.exists) {
          // Document with id == varuId doesn't exist.
          await DatabaseService(uid: user.uid).updateOrgData(
              orgType,
              orgName,
              email,
              orgID,
              contact,
              address,
              postal,
              city,
              state,
              user.uid,
              usertype,
              imageurl);
          // You can add data to Firebase Firestore here
        }
        return "Signed up";
      }else{
        user!.delete();
      }
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
    return null;
  }



  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  static SnackBar customSnackBar2({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.white, letterSpacing: 0.5),
      ),
    );
  }

  static Future<FirebaseApp> initializeFirebase({
    required BuildContext context,
  }) async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();

    User? user = FirebaseAuth.instance.currentUser;

    // if (user != null) {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(
    //       builder: (context) => const bottomNavigationBar(
    //       ),
    //     ),
    //   );
    // }

    return firebaseApp;
  }

  static Future<void> logout() async {
        try {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Remove all listeners
            GeofencingService.geofenceService
                .removeGeofenceStatusChangeListener(
                GeofencingService.onGeofenceStatusChanged);
            GeofencingService.geofenceService.removeLocationChangeListener(
                GeofencingService.onLocationChanged);
            GeofencingService.geofenceService
                .removeLocationServicesStatusChangeListener(
                GeofencingService.onLocationServicesStatusChanged);
            GeofencingService.geofenceService.removeActivityChangeListener(
                GeofencingService.onActivityChanged);
            GeofencingService.geofenceService.removeStreamErrorListener(
                GeofencingService.onError);

            // Stop the geofence service
            GeofencingService.geofenceService.stop();

            // Close stream controllers if applicable
            GeofencingService.geofenceStreamController.sink.close();
            GeofencingService.activityStreamController.sink.close();

            // Stop the list update timer
            GeofencingService.geofenceUpdateTimer?.cancel();
            GeofencingService.newGeofenceUpdateTimer?.cancel();

            // Clear list
            GeofencingService.geofenceList.clear();
            print("service deactivated");
          });
        }catch (e) {
          print("Error while stopping geofence service: $e");
        }
        _firebaseAuth.signOut();
        GeofencingService.userId = "";
      currentIndex = 0;
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      // Password reset email sent successfully
    } catch (error) {
      print('Password reset failed: $error');
    }
  }

  static Future<bool> checkAccountExists(String email) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users_data')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // If a document with the given email exists, the account exists
      return querySnapshot.size > 0;
    } catch (e) {
      // Handle the error if needed
      print('Error checking account existence: $e');
      return false;
    }
  }

}

