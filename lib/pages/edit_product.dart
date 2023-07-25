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

class EditProducts extends StatefulWidget {
  final String currentUserId;
  final String productId;

  EditProducts({
    required this.currentUserId,
    required this.productId,
  });

  @override
  State<EditProducts> createState() => _EditProductsState();
}

class _EditProductsState extends State<EditProducts> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController sizeController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  File? _file;
  bool isLoading = false;
  late User user;
  bool _descriptionValid = true;
  bool _sizeValid = true;
  bool _quantityValid = true;
  bool _priceValid = true;

  late DocumentSnapshot productDocument;
  String productId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    getProduct();
  }

  getProduct() async {
    setState(() {
      isLoading = true;
    });
    productDocument = await productsRef
        .doc(widget.currentUserId)
        .collection('userProducts')
        .doc(widget.productId)
        .get();

    if (productDocument.exists) {
      descriptionController.text = productDocument['description'];
      sizeController.text = productDocument['size'];
      quantityController.text = productDocument['quantity'].toString();
      priceController.text = productDocument['price'].toString();
    }

    setState(() {
      isLoading = false;
    });
  }

  Column builddescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Description",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            hintText: "Update Description",
            errorText: _descriptionValid ? null : "Description is too short",
          ),
        ),
      ],
    );
  }

  Column buildSizeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Size",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: sizeController,
          decoration: InputDecoration(
            hintText: "Update Size",
            errorText: _sizeValid ? null : "Description is too short",
          ),
        ),
      ],
    );
  }

  Column buildquantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Quantity",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: quantityController,
          keyboardType: TextInputType.number, // Set keyboard type to number
          decoration: InputDecoration(
            hintText: "Update Quantity",
            errorText: _quantityValid ? null : "Quantity is too long",
          ),
        ),
      ],
    );
  }

  Column buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Price",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: priceController,
          keyboardType: TextInputType.number, // Set keyboard type to number
          decoration: InputDecoration(
            hintText: "Update Price",
            errorText: _priceValid ? null : "Price is too long",
          ),
        ),
      ],
    );
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(_file!.readAsBytesSync())!;
    final compressedImageFile = File('$path/img_$productId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 95));
    setState(() {
      _file = compressedImageFile;
    });
  }

  Future<String?> uploadImage(File imageFile, String productId) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('products');
      UploadTask uploadTask = storageRef.child('$productId.jpg').putFile(imageFile);
      TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  updateProductData() async {
    setState(() {
      _descriptionValid =
          descriptionController.text.trim().length >= 3 && descriptionController.text.isNotEmpty;
      _sizeValid = sizeController.text.trim().isNotEmpty;
      _quantityValid = quantityController.text.trim().length <= 100;
      _priceValid = priceController.text.trim().length <= 100;
    });

    if (_descriptionValid && _quantityValid && _priceValid && _sizeValid) {
      if (_file != null) {
        String? mediaUrl = await uploadImage(_file!, productId);

        if (mediaUrl != null) {
          // Update the 'mediaUrl' field in Firestore
          await productsRef
              .doc(widget.currentUserId)
              .collection('userProducts')
              .doc(widget.productId)
              .update({
            'description': descriptionController.text,
            'size': sizeController.text,
            'quantity': int.tryParse(quantityController.text), // Parse quantity as integer
            'price': int.tryParse(priceController.text), // Parse price as integer
            'mediaUrl': mediaUrl,
          });

          final snackBar = SnackBar(content: Text("Product updated!"));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          final snackBar = SnackBar(content: Text("Failed to update product."));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        // If no new image is selected, only update the text fields
        await productsRef
            .doc(widget.currentUserId)
            .collection('userProducts')
            .doc(widget.productId)
            .update({
          'description': descriptionController.text,
          'size': sizeController.text,
          'quantity': int.tryParse(quantityController.text), // Parse quantity as integer
          'price': int.tryParse(priceController.text), // Parse price as integer
        });

        final snackBar = SnackBar(content: Text("Product updated!"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> delete() async {
    await productsRef
        .doc(widget.currentUserId)
        .collection('userProducts')
        .doc(widget.productId)
        .delete();
    final snackBar = SnackBar(content: Text("Product deleted!"));
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
          title: const Text('Edit Item Photo'),
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
          "Edit Item",
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
                                    image: CachedNetworkImageProvider(productDocument['mediaUrl']),
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
                      builddescriptionField(),
                      buildquantityField(),
                      buildPriceField(),
                      buildSizeField(),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: updateProductData,
                  child: Text(
                    "Update Product",
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
                      "Delete Product",
                      style: TextStyle(color: Colors.red, fontSize: 20.0),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
