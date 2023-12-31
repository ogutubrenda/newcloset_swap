import 'dart:io';
import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/home.dart' as H;
import 'package:betterclosetswap/pages/home.dart';
//import 'package:betterclosetswap/pages/login_page.dart';
//import 'package:betterclosetswap/pages/signup_screen.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as Im;
import 'package:path_provider/path_provider.dart';
//import 'package:google_sign_in/google_sign_in.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  //final String userId;

  EditProfile({
    required this.currentUserId,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  File? _file;

  late User user;
  bool _bioValid = true;
  bool _displayNameValid = true;
  //final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot document = await usersRef.doc(widget.currentUserId).get();
    user = User.fromDocument(document);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Display Name",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null : "Display Name is too short",
          ),
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update your bio",
            errorText: _bioValid ? null : "Your bio is too long",
          ),
        ),
      ],
    );
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(_file!.readAsBytesSync())!;
    final compressedImageFile = File('$path/img_${user.id}.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 95));
    setState(() {
      _file = compressedImageFile;
    });
  }

  Future<String?> uploadImage(File imageFile, String currentUserId) async {
    try {
      final userRef = FirebaseStorage.instance.ref().child('users');
      UploadTask uploadTask =
          userRef.child('$currentUserId.jpg').putFile(imageFile);
      TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  

  updateProfileData() async {
    setState(() {
      bioController.text.trim().length < 3 || bioController.text.isEmpty
          ? _bioValid = false
          : _bioValid = true;

      displayNameController.text.trim().length > 100
          ? _displayNameValid = false
          : _displayNameValid = true;
    });

    if (_bioValid && _displayNameValid) {
      if (_file != null) {
        await compressImage(); // Compress the image
        String? photoUrl = await uploadImage(_file!, widget.currentUserId);

        if (photoUrl != null) {
          // Update the profile data in Firestore
          await usersRef
              .doc(widget.currentUserId)
              .update({
            'bio': bioController.text,
            'displayName': displayNameController.text,
            'photoUrl': photoUrl,
          });

          final snackBar = SnackBar(content: Text("Profile updated!"));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          final snackBar = SnackBar(content: Text("Failed to update profile."));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        // If no new image is selected, only update the text fields
        await usersRef
            .doc(widget.currentUserId)
            .update({
          'bio': bioController.text,
          'displayName': displayNameController.text,
        });

        final snackBar = SnackBar(content: Text("Profile updated!"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> logout() async {
    // await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  void handleTakePhoto() async {
    Navigator.pop(context);
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
      });
    }
  }

  void handleChooseFromGallery() async {
    Navigator.pop(context);
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
      });
    }
  }

  void tapShowDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Edit Profile Photo'),
          children: <Widget>[
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Take Photo'),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Choose from Gallery'),
              onPressed: handleChooseFromGallery,
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30,
              color: Colors.green.shade900,
            ),
          ),
        ],
      ),
      body: isLoading
          ? CircularProgress()
          : ListView(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: GestureDetector(
                    onTap: tapShowDialog,
                    child: Container(
                      height: 200.0,
                      width: 200.0,
                      child: AspectRatio(
                        aspectRatio: 1.0, // Set the aspect ratio to 1.0 for a square display
                        child: _file != null
                            ? Image.file(
                                _file!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(user.photoUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      buildDisplayNameField(),
                      buildBioField(),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: updateProfileData,
                  child: Text(
                    "Update Profile",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: logout,
                    icon: Icon(Icons.cancel, color: Colors.red),
                    label: Text(
                      "Logout",
                      style: TextStyle(color: Colors.red, fontSize: 20.0),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
