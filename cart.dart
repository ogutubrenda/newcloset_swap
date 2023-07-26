import 'dart:async';
import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/checkout.dart';
import 'package:betterclosetswap/widgets/product.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class Cart extends StatefulWidget {
  final User currentUser;

  Cart({required this.currentUser});

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  List<CartItem> cartItems = [];
  StreamSubscription<QuerySnapshot>? cartItemsSubscription;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  @override
  void dispose() {
    cartItemsSubscription?.cancel();
    super.dispose();
  }

  void fetchCartItems() {
    cartItemsSubscription = FirebaseFirestore.instance
        .collection('cart')
        .doc(widget.currentUser.id)
        .collection('cartItems')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        cartItems = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CartItem(
            productId: doc.id,
            description: data['description'],
            price: data['price'],
            mediaUrl: data['mediaUrl'],
            size: data['size'],
            username: data['username'],
            quantity: data['quantity'],
          );
        }).toList();
      });
    });
  }

  int calculateTotal() {
    int total = 0;
    for (var cartItem in cartItems) {
      total += cartItem.price ;
    }
    return total;
  }

  void addToCart(CartItem cartItem) async {
  final cartRef = FirebaseFirestore.instance
      .collection('cart')
      .doc(widget.currentUser.id)
      .collection('cartItems')
      .doc(cartItem.productId);

  final cartItemDoc = await cartRef.get();

  if (cartItemDoc.exists) {
    // Product already exists in cart, increment the quantity
    cartRef.update({'quantity': FieldValue.increment(1)});
  } else {
    // Product doesn't exist in cart, set the quantity to 1
    cartRef.set({
      'description': cartItem.description,
      'price': cartItem.price,
      'mediaUrl': cartItem.mediaUrl,
      'size': cartItem.size,
      'username': cartItem.username,
      'quantity': 1, // Set the quantity to 1
    });
  }
}


  void removeFromCart(String productId) async {
    final cartRef = FirebaseFirestore.instance
        .collection('cart')
        .doc(widget.currentUser.id)
        .collection('cartItems')
        .doc(productId);

    await cartRef.delete();
  }

  void checkout() {
    int totalAmount = calculateTotal();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(totalAmount: totalAmount, cartItems: cartItems),
      ),
    );
  }

  void handleAddToCart(CartItem cartItem) {
    addToCart(cartItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product added to cart.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Text('Your cart is empty.'),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartItems[index];
                      return Card(
                        elevation: 2.0,
                        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          leading: Image.network(
                            cartItem.mediaUrl,
                            width: 60.0,
                            height: 60.0,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            cartItem.description,
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Size: ${cartItem.size}', // Display the size here
                                style: TextStyle(fontSize: 14.0),
                              ),
                              Text(
                                'Price: \$${cartItem.price}',
                                style: TextStyle(fontSize: 14.0),
                              ),
                              Text(
                                'Quantity Available: ${cartItem.quantity}',
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => removeFromCart(cartItem.productId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Total: \$${calculateTotal()}',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: checkout,
            child: Text('Checkout'),
          ),
        ],
      ),
    );
  }
}
