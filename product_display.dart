import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListPage extends StatelessWidget {
  final String currentUserId;

  ProductListPage({required this.currentUserId, required String productId, required String productOwnerId, required String productphotoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('ownerId', isNotEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(
                  product['mediaUrl'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(product['description']),
                subtitle: Text('Price: \$${product['price']}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    // Add to cart logic
                  },
                  child: Text('Add to Cart'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
