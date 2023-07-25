import 'dart:async';

import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/comments.dart';
import 'package:betterclosetswap/pages/edit_post.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/widgets/custom_image.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      // Handle the case when data is null or empty
      return Post(
        postId: '',
        ownerId: '',
        username: '',
        location: '',
        description: '',
        mediaUrl: '',
        likes: {},
      );
    }

    return Post(
      postId: data['postId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      username: data['username'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      likes: data['likes'] ?? {},
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
  _PostState createState() => _PostState(
        postId: postId,
        ownerId: ownerId,
        username: username,
        location: location,
        description: description,
        mediaUrl: mediaUrl,
        likes: likes,
        likeCount: getLikeCount(),
        isLiked: true,
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser!.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;

  _PostState({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
    required this.likeCount,
    required this.isLiked,
  });
  void editPost() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditPosts(currentUserId: currentUserId, postId: postId,)));
  }
  handleShowDialog() {
showDialog(
context: context,
builder: (BuildContext context) {
return SimpleDialog(
          title: const Text('Edit Post?'),
          children: <Widget>[
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Yes'),
              onPressed: editPost,
            ),
            
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("No"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
},
);
}

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
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
          subtitle: Text(location),
          trailing: IconButton(
            onPressed:  handleShowDialog,
            icon: Icon(Icons.more_vert),
          ),
        );
      },
    );
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
          removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});
          addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }
  addLikeToActivityFeed(){
    bool isNotPostOwner = currentUser!= ownerId;
    if(isNotPostOwner){
       activityFeedRef
    .doc(ownerId)
    .collection("feedItems")
    .doc(postId)
    .set({
      "type":"like",
      "username":currentUser?.username,
      "userId": currentUser?.id,
      "userProfileImg":currentUser?.photoUrl,
      "postId":postId,
      "mediaUrl":mediaUrl,
      "timestamp":timestamp,

    });
  }
    }
    
   
  removeLikeFromActivityFeed(){
    bool isNotPostOwner = currentUser!= ownerId;
    if(isNotPostOwner){
      activityFeedRef
    .doc(ownerId)
    .collection("feedItems")
    .doc(postId)
    .get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    }
    
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart ? Icon(Icons.favorite, size: 80.0, color: Colors.red,) : Text("")
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink.shade700,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,),
              child: Icon(
                Icons.chat,
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
                "$username",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(description),
            )
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}
showComments(BuildContext context, {required String postId, required String ownerId, required String mediaUrl}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Comments(postId: postId, postOwnerId: ownerId, postphotoUrl: mediaUrl,),
    ),
  );
}
