import 'dart:async';
import 'package:animator/animator.dart';
import 'package:betterclosetswap/pages/comments.dart';
import 'package:betterclosetswap/widgets/custom_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../pages/home.dart';

// ignore: must_be_immutable
class Post extends StatefulWidget {
  final String userId;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  String? ownerId;
  String? postId;
  String? description;
  Map<dynamic, dynamic>? likes;

  Post({super.key, 
    required this.userId,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.displayName,
    required this.bio,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      userId: doc['id'],
      username: doc['username'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _PostState createState() => _PostState(

        userId: userId,
        username: username,
        email: email,
        photoUrl: photoUrl,
        displayName: displayName,
        bio: bio,
        likeCount: getLikeCount(likes), location: '',
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.userId ?? '';
  final String userId;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  final String location;
  bool showHeart = false;
  int likeCount;
  late bool isLiked;

  _PostState( {
    required this.location,
    required this.userId,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.displayName,
    required this.bio,
    required this.likeCount,
  });
  
  Object? get ownerId => null;
  
  String? get postId => null;

  Widget buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        User user = User.fromDocument(snapshot.data as DocumentSnapshot<Object?>);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.userId),
            child: Text(
              user.username,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  // ignore: avoid_print
                  onPressed: () => print(handleDeletePost(context)),
                  icon: const Icon(Icons.more_vert),
                )
              : const Text(''),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: const Text("Remove this post?"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                deletePost();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  deletePost() async {
    postsRef
        .doc(ownerId as String?)
        .collection('userPosts')
        .doc(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    await storageRef.child("post_$postId.jpg").delete();

    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerId as String?)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .get();
    for (var doc in activityFeedSnapshot.docs) {
      if (doc.exists) {
        doc.reference.delete();
      }
    }

    QuerySnapshot commentsSnapshot = await commentsRef
        .doc(postId)
        .collection('comments')
        .get();
    for (var doc in commentsSnapshot.docs) {
      if (doc.exists) {
        doc.reference.delete();
      }
    }
  }

  void handleLikePost() {
    bool isLiked = widget.likes?[currentUserId] == true;

    if (isLiked) {
      postsRef
          .doc(ownerId as String?)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        widget.likes?[currentUserId] = false;
      });
    } else {
      postsRef
          .doc(ownerId as String?)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        widget.likes?[currentUserId] = true;
        showHeart = true;
      });
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerId as String?)
          .collection("feedItems")
          .doc(postId)
          .set({
        "type": "like",
        "username": currentUser?.username,
        "userId": currentUser?.userId,
        "userProfileImg": currentUser?.photoUrl,
        "postId": postId,
        "photoUrl": photoUrl,
        "timestamp": timestamp,
      });
    }
  }

  void removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerId as String?)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  Widget buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(photoUrl),
          showHeart
              ? Animator(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (context, anim, child) => Transform.scale(
                    scale: anim.value,
                    child: const Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.red,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
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
            const Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            const Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId as String?,
                photoUrl: photoUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
  children: <Widget>[
    Container(
      margin: const EdgeInsets.only(left: 20.0),
      child: Text(
        "$likeCount likes",
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),

      ],
    );
  }

  

  @override
  Widget build(BuildContext context) {
    isLiked = (widget.likes?[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
  
  showProfile(BuildContext context, {required profileId}) {}
}

void showComments(BuildContext context,
    {String? postId, String? ownerId, String? photoUrl}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId!,
        postOwnerId: ownerId!,
        postphotoUrl: photoUrl!,
      );
    }),
  );
}

       