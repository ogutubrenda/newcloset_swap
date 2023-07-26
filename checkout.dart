import 'package:betterclosetswap/pages/cart.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  late final int totalAmount;
  final List<CartItem> cartItems;

  CheckoutScreen({required this.totalAmount, required this.cartItems});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedLocation = 'Nairobi';
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  void updateTotalAmount() {
    setState(() {
      switch (selectedLocation) {
        case 'Nairobi':
          widget.totalAmount += 5;
          break;
        case 'Mombasa':
          widget.totalAmount += 20;
          break;
        case 'Nakuru':
          widget.totalAmount += 10;
          break;
      }
    });
  }

  void completeOrder() async {
    String name = nameController.text;
    String phone = phoneController.text;

    // Delete products from cart
    for (var cartItem in widget.cartItems) {
      await FirebaseFirestore.instance
          .collection('cart')
          .doc(currentUser!.id)
          .collection('cartItems')
          .doc(cartItem.productId)
          .delete();
    }

    // Add products to the "orders" collection under the current user
    for (var cartItem in widget.cartItems) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentUser!.id)
          .collection('orderedItems')
          .doc(cartItem.productId)
          .set({
        'productId': cartItem.productId,
        'description': cartItem.description,
        'price': cartItem.price,
        'mediaUrl': cartItem.mediaUrl,
        'size': cartItem.size,
        'username': cartItem.username,
        'quantity': cartItem.quantity,
        'name': name,
        'phone': phone,
      });
    }

    // Update quantity and move products to "sold" under ownerId in "products" collection
    for (var cartItem in widget.cartItems) {
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(cartItem.productId)
          .get();
      if (productSnapshot.exists) {
        int quantity = productSnapshot['quantity'];
        String ownerId = productSnapshot['ownerId'];
        if (quantity == 1) {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(cartItem.productId)
              .delete();
        } else {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(cartItem.productId)
              .update({'quantity': quantity - 1});
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .collection('sold')
            .doc(cartItem.productId)
            .set({
          'productId': cartItem.productId,
          'description': cartItem.description,
          'price': cartItem.price,
          'mediaUrl': cartItem.mediaUrl,
          'size': cartItem.size,
          'username': cartItem.username,
          'quantity': cartItem.quantity,
          'name': name,
          'phone': phone,
        });

        // Create activity feed item for the order
        await FirebaseFirestore.instance
            .collection('activityFeed')
            .doc(ownerId)
            .collection('feedItems')
            .doc(currentUser!.id)
            .set({
          'type': 'order',
          'username': currentUser!.username,
          'userId': currentUser!.id,
          'postId': cartItem.productId,
          'userProfileImg': currentUser!.photoUrl,
          'commentData': '',
          'timestamp': Timestamp.now(),
          'mediaUrl': cartItem.mediaUrl,
        });
      }
    }

    // Navigate back to the Cart page
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = widget.cartItems[index];
                return ListTile(
                  title: Text(cartItem.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: \$${cartItem.price}'),
                      Text('Quantity: ${cartItem.quantity}'),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: \$${widget.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Location:',
                  style: TextStyle(fontSize: 16.0),
                ),
                DropdownButton<String>(
                  value: selectedLocation,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedLocation = newValue!;
                      updateTotalAmount();
                    });
                  },
                  items: <String>['Nairobi', 'Mombasa', 'Nakuru']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: completeOrder,
            child: Text('Complete Order'),
          ),
        ],
      ),
    );
  }
}
