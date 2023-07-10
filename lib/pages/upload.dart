import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:betterclosetswap/pages/home.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart'; 
class Upload extends StatefulWidget {
  final User currentUser;
  //const Upload({super.key});
  Upload({required this.currentUser});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  Uint8List? _file;
  bool isUploading = false;
  String postId = Uuid().v4();

  
  pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(source: source);
  if (file != null) {
    return await file.readAsBytes();
  }
}

  selectImage(parentContext){
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Create a Post'),
          children: <Widget>[
            SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Take a photo'),
                onPressed: () async {
                  Navigator.pop(context);
                  Uint8List file = await pickImage(ImageSource.camera);
                  setState(() {
                    _file = file;
                  });
                }),
            SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Choose from Gallery'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(ImageSource.gallery);
                  setState(() {
                    _file = file;
                  });
                }),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }
  Container buildSplashScreen(){
    return Container(
      color: Theme.of(context).hintColor.withOpacity(0.6),
      child: Column (
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          //SvgPicture.asset('assets\image2vector.svg'),
          Padding(
            padding: EdgeInsets.only(top:20.0),
             
          child: ElevatedButton(
  onPressed: ()=> selectImage(context),
  //color: Colors.blue,
  style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
  child: Text(
    "Add Post", 
    style: TextStyle(
      color: Colors.white,
      fontSize: 22.0,
    ),
    ),
    
)

          ),
         
        ],
        )
    );
  }
clearImage(){
  setState((){
    _file = null;
  });
}
compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Uint8List? imageBytes = _file; // Assuming _file contains the Uint8List image data

    Im.Image? decodedImage = Im.decodeImage(imageBytes!);
    final compressedImageFile = File('$path/image_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(decodedImage!, quality: 85));

    setState(() {
      _file = compressedImageFile.readAsBytesSync();
    });
  }

  Future <String> uploadImage(Uint8List? file) async {
    final postRef = storageRef.child("post_$postId.jpg");
    firebase_storage.UploadTask uploadTask = postRef.putData(file!);
    firebase_storage.TaskSnapshot storageSnap = await uploadTask.whenComplete(() => null);
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;

    // Use the downloadUrl as needed
  }

  createPostInFirestore({required String mediaUrl, required String location, required String description}) {
    postsRef
        .doc(widget.currentUser.id)
        .collection("userPosts")
        .doc(postId)
        .set({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": FieldValue.serverTimestamp(),
      "likes": {},
      "username" : widget.currentUser.username,
    });
}


handleSubmit() async {
  setState(() {
    isUploading = true;
  });
  await compressImage();
  String mediaUrl = await uploadImage(_file);
  createPostInFirestore(
    mediaUrl: mediaUrl,
    location: locationController.text,
    description: captionController.text,
  );
  captionController.clear();
  locationController.clear();
  setState((){
    _file = null;
    isUploading = false;
    postId = Uuid().v4();
  });
}

  Scaffold buildUploadFom(){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: clearImage,
        ),
        title: Text("Caption Post",
        style: TextStyle(color: Colors.black,
        
        ),
        
        ),
        actions: [
          ElevatedButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              "Post",
              style: TextStyle(color:Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
              )
            ),
          ),
        ],
        
      ),
      body: ListView(
  children: <Widget>[
    isUploading? LinearProgress() : Text(""),
    Container(
      height: 220.0,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(_file!),
                fit: BoxFit.cover,)),

          ))
      )
    ),
    Padding(
      padding: EdgeInsets.only(top: 10.0)),
      ListTile(
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(widget.currentUser.photoUrl),
        ),
        title: Container(
          width: 250.0,
          child: TextField(
            controller: captionController,
            decoration: InputDecoration(
              hintText: "Write your caption...",
              border: InputBorder.none,
              ),
              
          ),
        ),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.pin_drop, color: Colors.amber.shade300, size: 35.0,),
          title: Container(
            width: 250.0,
            child: TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: "Enter the location",
                border: InputBorder.none,
              )
            ),
          ),
        ),
       Container(
  width: 200.0,
  height: 100.0,
  alignment: Alignment.center,
  child: ElevatedButton.icon(
    label: Text(
      "Use your current location",
      style: TextStyle(
        color: Colors.white,
      ),
    ),
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      primary: Colors.indigo.shade900,
    ),
    onPressed: () => getUserLocation,
    icon: Icon(
      Icons.my_location,
      color: Colors.white,
    ),
  ),
)
  ],
),

    );
  }
  



getUserLocation() async {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
 // Placemark placemark = placemarks[0];
  //String completeAddress = placemark.name! + ", " + placemark.subLocality! + ", " + placemark.locality! + ", " + placemark.administrativeArea! + ", " + placemark.country!;
  //print(completeAddress);
  //String formattedAddress = "${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
  //print(formattedAddress);
}


  @override
  Widget build(BuildContext context) {
    return _file == null ? buildSplashScreen(): buildUploadFom();
  }
}