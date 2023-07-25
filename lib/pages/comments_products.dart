import 'package:betterclosetswap/widgets/header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../widgets/progress.dart';
import 'home.dart';

class CommentsProducts extends StatefulWidget {
  final String productId;
  final String productOwnerId;
  final String postphotoUrl;

  CommentsProducts({
    required this.productId,
    required this.productOwnerId,
    required this.postphotoUrl, required String productmediaUrl,
  });

  @override
  CommentsProductsState createState() => CommentsProductsState(
        productId: this.productId,
        productOwnerId: this.productOwnerId,
        postphotoUrl: this.postphotoUrl,
      );
}

class CommentsProductsState extends State<CommentsProducts> {
  TextEditingController commentController = TextEditingController();
  final String productId;
  final String productOwnerId;
  final String postphotoUrl;

  CommentsProductsState({
    required this.productId,
    required this.productOwnerId,
    required this.postphotoUrl,
  });

  buildComments() {
    return StreamBuilder(
      stream: commentsRef
          .doc(productId)
          .collection('comments')
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgress();
        }
        List<Comment> comments = [];
        snapshot.data?.docs.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments.map((comment) => comment.build(context)).toList(),
        );
      },
    );
  }

  addComment() {
    commentsRef.doc(productId).collection("comments").add({
      "username": currentUser?.username,
      "comment": commentController.text,
      "timestamp": FieldValue.serverTimestamp(),
      "avatarUrl": currentUser?.photoUrl,
      "userId": currentUser?.id,
    });

    bool isNotProductOwnerId = widget.productOwnerId != currentUser?.id;

    if (isNotProductOwnerId) {
      activityFeedRef.doc(productOwnerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "timestamp": FieldValue.serverTimestamp(),
        "productId": productId,
        "userId": currentUser?.id,
        "username": currentUser?.username,
        "userProfileImg": currentUser?.photoUrl,
        "photoUrl": postphotoUrl,
      });
    }

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: OutlinedButton(
              onPressed: addComment,
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
              ),
              child: Text("Post"),
            ),
          )
        ],
      ),
    );
  }
}

class Comment {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final DateTime timestamp;

  Comment({
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.comment,
    required this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'].toDate(),
      avatarUrl: doc['avatarUrl'],
    );
  }

  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp)),
        ),
        Divider(),
      ],
    );
  }
}
