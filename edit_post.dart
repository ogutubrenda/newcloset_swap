import 'dart:io';
import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/pages/login_page.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class EditPosts extends StatefulWidget {
  final String currentUserId;
  final String postId;

  EditPosts({
    required this.currentUserId,
    required this.postId,
  });

  @override
  State<EditPosts> createState() => _EditPostsState();
}

class _EditPostsState extends State<EditPosts> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File? _file;
  bool isLoading = false;
  late User user;
  bool _captionValid = true;
  bool _locationValid = true;
  //final GoogleSignIn googleSignIn = GoogleSignIn();
  late DocumentSnapshot postDocument;
  String postId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    getPost();
  }

  getPost() async {
    setState(() {
      isLoading = true;
    });
    postDocument = await postsRef
        .doc(widget.currentUserId)
        .collection('userPosts')
        .doc(widget.postId)
        .get();
    captionController.text = postDocument['description'];
    locationController.text = postDocument['location'];
    setState(() {
      isLoading = false;
    });
  }

  Column buildCaptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Caption",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: captionController,
          decoration: InputDecoration(
            hintText: "Update Caption",
            errorText: _captionValid ? null : "Caption is too short",
          ),
        ),
      ],
    );
  }

  Column buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Location",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            hintText: "Update Location",
            errorText: _locationValid ? null : "Location is too long",
          ),
        ),
      ],
    );
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(_file!.readAsBytesSync())!;
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 95));
    setState(() {
      _file = compressedImageFile;
    });
  }

  Future<String?> uploadImage(File imageFile, String postId) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('posts');
      UploadTask uploadTask = storageRef.child('$postId.jpg').putFile(imageFile);
      TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  updatePostData() async {
    setState(() {
      captionController.text.trim().length < 3 || captionController.text.isEmpty
          ? _captionValid = false
          : _captionValid = true;

      locationController.text.trim().length > 100 ? _locationValid = false : _locationValid = true;
    });

    if (_captionValid && _locationValid) {
      if (_file != null) {
        String? mediaUrl = await uploadImage(_file!, postId);

        if (mediaUrl != null) {
          // Update the 'mediaUrl' field in Firestore
          await postsRef
              .doc(widget.currentUserId)
              .collection('userPosts')
              .doc(widget.postId)
              .update({
            'description': captionController.text,
            'location': locationController.text,
            'mediaUrl': mediaUrl,
          });

          final snackBar = SnackBar(content: Text("Post updated!"));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          final snackBar = SnackBar(content: Text("Failed to update post."));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        // If no new image is selected, only update the text fields
        await postsRef
            .doc(widget.currentUserId)
            .collection('userPosts')
            .doc(widget.postId)
            .update({
          'description': captionController.text,
          'location': locationController.text,
        });

        final snackBar = SnackBar(content: Text("Post updated!"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

 Future<void> delete() async {
  await postsRef
    .doc(widget.currentUserId)
    .collection('userPosts')
    .doc(widget.postId)
    .delete();
     final snackBar = SnackBar(content: Text("Post deleted!"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
          title: const Text('Edit Post Photo'),
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
          "Edit Post",
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
                                    image: CachedNetworkImageProvider(postDocument['mediaUrl']),
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
                      buildCaptionField(),
                      buildLocationField(),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: updatePostData,
                  child: Text(
                    "Update Post",
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
                    onPressed: delete,
                    icon: Icon(Icons.cancel, color: Colors.red),
                    label: Text(
                      "Delete Post",
                      style: TextStyle(color: Colors.red, fontSize: 20.0),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
