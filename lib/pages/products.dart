import 'dart:io';
import 'dart:typed_data';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Products extends StatefulWidget {
  final User currentUser;

  const Products({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products>
    with AutomaticKeepAliveClientMixin {
  TextEditingController captionController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController(); // Added quantityController
  File? _file;
  bool isUploading = false;
  String productId = const Uuid().v4();
  String selectedSize = "M";
  String selectedCategory = "Men";
  String selectedType = "Shirt";

  List<String> sizes = ["S", "M", "L", "XL", "XS"];
  List<String> categories = ["Men", "Women", "Children", "Accessories"];
  List<String> types = [
    "Shirt",
    "Trouser",
    "T-shirt",
    "Jean Trousers",
    "Jean Shorts",
    "Sweater",
    "Hoody"
  ];

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

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Create a Post'),
          children: <Widget>[
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Take a photo'),
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

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).hintColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/image2vector.svg'),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
              onPressed: () => selectImage(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                "Add an Item",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      _file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(_file!.readAsBytesSync())!;
    final compressedImageFile =
        File('$path/img_$productId.jpg')..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 95));
    setState(() {
      _file = compressedImageFile;
    });
  }

  Future<String> productImage(Uint8List? file) async {
    final firebase_storage.Reference storageRef =
        firebase_storage.FirebaseStorage.instance.ref();
    final productTask =
        storageRef.child("post_$productId.jpg").putData(file!);
    final snapshot = await productTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  createProductInFirestore({
    required String mediaUrl,
    required String description,
    required int price,
    required int quantity,
  }) async {
    await FirebaseFirestore.instance
        .collection("products")
        .doc(widget.currentUser.id)
        .collection("userProducts")
        .doc(productId)
        .set({
      "productId": productId,
      "ownerId": widget.currentUser.id,
      "mediaUrl": mediaUrl,
      "description": description,
      "price": price,
      "quantity": quantity,
      "size": selectedSize,
      "category": selectedCategory,
      "type": selectedType,
      "timestamp": FieldValue.serverTimestamp(),
      "likes": {},
      "username": widget.currentUser.username,
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await productImage(_file!.readAsBytesSync());
    createProductInFirestore(
      mediaUrl: mediaUrl,
      description: captionController.text,
      price: int.parse(priceController.text),
      quantity: int.parse(quantityController.text), // Get quantity from the text field
    );
    captionController.clear();
    priceController.clear();
    quantityController.clear();
    setState(() {
      _file = null;
      isUploading = false;
      productId = const Uuid().v4();
    });
  }

  Scaffold buildProductForm() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: clearImage,
        ),
        title: const Text(
          "Caption Post",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: const Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? LinearProgress() : const Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(_file!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 10.0)),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: SizedBox(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: const InputDecoration(
                  hintText: "Write a description...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.attach_money,
              color: Colors.green,
              size: 35.0,
            ),
            title: SizedBox(
              width: 250.0,
              child: TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter the price",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.shopping_bag,
              color: Colors.orange,
              size: 35.0,
            ),
            title: SizedBox(
              width: 250.0,
              child: TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter the quantity",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.accessibility,
              color: Colors.blue,
              size: 35.0,
            ),
            title: DropdownButtonFormField<String>(
              value: selectedSize,
              items: sizes.map((size) {
                return DropdownMenuItem<String>(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSize = value!;
                });
              },
              decoration: const InputDecoration(
                hintText: "Select size",
                border: InputBorder.none,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.person,
              color: Colors.pink,
              size: 35.0,
            ),
            title: DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(
                hintText: "Select category",
                border: InputBorder.none,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.shopping_bag,
              color: Colors.orange,
              size: 35.0,
            ),
            title: DropdownButtonFormField<String>(
              value: selectedType,
              items: types.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
              decoration: const InputDecoration(
                hintText: "Select type",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _file == null ? buildSplashScreen() : buildProductForm();
  }
}
