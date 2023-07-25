import 'package:betterclosetswap/widgets/custom_image.dart';
import 'package:betterclosetswap/widgets/product.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductTile extends StatelessWidget {
  //const ProductTile({super.key});
  final Product product;

  ProductTile (this.product);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> print ('showing product'),
      child: cachedNetworkImage(product.mediaUrl),
    );
  }
}