import 'package:betterclosetswap/widgets/custom_image.dart';
import 'package:betterclosetswap/widgets/post.dart';
import 'package:flutter/material.dart';

import '../pages/post_screen.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  void showPost(BuildContext context, {String? postId, String? userId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId!,
          userid: userId!, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context, postId: post.postId, userId: post.ownerId),
      child: cachedNetworkImage(post.photoUrl),
    );
  }
}
