import 'dart:async';

import 'package:betterclosetswap/models/user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:betterclosetswap/pages/cart.dart';
import 'package:betterclosetswap/pages/edit_product.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/widgets/custom_image.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meta/meta.dart';

class CartItem {
  final String productId;
  final String description;
  final int price;
  final String mediaUrl;
  final String size;
  final String username;
  final int quantity;
  

  CartItem({
    required this.productId,
    required this.description,
    required this.price,
    required this.mediaUrl,
    required this.size,
    required this.username,
    required this.quantity,
   
  });
}

class Product extends StatefulWidget {
  final String productId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final String gender;
  final String size;
  final String type;
  final int price;
  final int quantity;

  final dynamic likes;
  final Function(CartItem) onAddToCart;

  Product({
    required this.productId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.gender,
    required this.size,
    required this.quantity,
    required this.type,
    required this.price,
    required this.likes,
    required this.onAddToCart,
  });

  factory Product.fromDocument(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      // Handle the case when data is null or empty
      return Product(
        productId: '',
        ownerId: '',
        username: '',
        location: '',
        description: '',
        mediaUrl: '',
        gender: '',
        size: '',
        type: '',
        price: 0,
        quantity: 0,
        likes: {},
        onAddToCart: (CartItem cartItem) {},
      );
    }

    return Product(
      productId: data['productId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      username: data['username'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      gender: data['gender'] ?? '',
      size: data['size'] ?? '',
      type: data['type'] ?? '',
      price: data['price'] ?? 0,
      quantity: data['quantity'] ?? 0,
      likes: data['likes'] ?? {},
      onAddToCart: (CartItem cartItem) {},
    );
  }

  int getLikeCount() {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count++;
      }
    });
    return count;
  }

  @override
  _ProductState createState() => _ProductState();
}

class _ProductState extends State<Product> {
  final String currentUserId = currentUser!.id;
  int likeCount = 0;
  bool isLiked = false;
  bool showHeart = false;

  @override
  void initState() {
    super.initState();
    likeCount = widget.getLikeCount();
    isLiked = widget.likes[currentUserId] == true;
  }

  void editProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProducts(
          currentUserId: currentUserId,
          productId: widget.productId,
        ),
      ),
    );
  }

  void handleShowDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Edit Product Details?'),
          children: <Widget>[
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Yes'),
              onPressed: editProduct,
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void handleLikeProduct() {
    bool _isLiked = widget.likes[currentUserId] == true;

    if (_isLiked) {
      postsRef
          .doc(widget.ownerId)
          .collection('userProducts')
          .doc(widget.productId)
          .update({'likes.$currentUserId': false});
      setState(() {
        likeCount -= 1;
        isLiked = false;
        widget.likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      productsRef
          .doc(widget.ownerId)
          .collection('userProducts')
          .doc(widget.productId)
          .update({'likes.$currentUserId': true});
      setState(() {
        likeCount += 1;
        isLiked = true;
        widget.likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  void addToCart() async {
  CartItem cartItem = CartItem(
    productId: widget.productId,
    description: widget.description,
    price: widget.price,
    mediaUrl: widget.mediaUrl,
    size: widget.size,
    username: widget.username,
    quantity: widget.quantity,
  );

  widget.onAddToCart(cartItem); // Call the onAddToCart callback with the cartItem

  final cartRef = FirebaseFirestore.instance
      .collection('cart')
      .doc(currentUserId)
      .collection('cartItems')
      .doc(cartItem.productId);

  final cartItemDoc = await cartRef.get();

  if (cartItemDoc.exists) {
    cartRef.update({'quantity': FieldValue.increment(1)});
  } else {
    cartRef.set({
      'description': cartItem.description,
      'price': cartItem.price,
      'mediaUrl': cartItem.mediaUrl,
      'size': cartItem.size,
      'username': cartItem.username,
      'quantity': cartItem.quantity,
    });
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Product added to cart.'),
    ),
  );
}


  Widget buildProductHeader() {
    return FutureBuilder(
      future: usersRef.doc(widget.ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgress();
        }
        User user = User.fromDocument(snapshot.data!);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(widget.location),
          trailing: IconButton(
            onPressed: handleShowDialog,
            icon: Icon(Icons.more_vert),
          ),
        );
      },
    );
  }

  Widget buildProductImage() {
    return GestureDetector(
      onDoubleTap: handleLikeProduct,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(widget.mediaUrl),
          showHeart ? Icon(Icons.favorite, size: 80.0, color: Colors.red) : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget buildProductFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikeProduct,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink.shade700,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: addToCart,
              child: Icon(
                Icons.add_shopping_cart,
                size: 28.0,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "Quantity: ${widget.quantity}",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "Size: ${widget.size}",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "${widget.username}",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(widget.description)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildProductHeader(),
        buildProductImage(),
        buildProductFooter(),
      ],
    );
  }
}
