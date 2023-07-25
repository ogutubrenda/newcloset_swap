// ignore_for_file: unused_local_variable
import 'package:betterclosetswap/widgets/header.dart';
import 'package:betterclosetswap/widgets/post.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:betterclosetswap/pages/home.dart';

class PostScreen extends StatelessWidget {
  final String userid;
  final String postId;

  const PostScreen({
    Key? key,
    required this.userid,
    required this.postId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: postsRef.doc(userid).collection('userPosts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgress();
        }
        Post post = Post.fromDocument(snapshot.data!);
        String titleText = post.description ?? '';
        return Center(
          child: Scaffold(
            appBar: header(context, titleText: titleText),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
