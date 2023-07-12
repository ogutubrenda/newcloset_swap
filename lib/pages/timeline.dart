import 'package:betterclosetswap/pages/search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:betterclosetswap/widgets/header.dart';

import '../models/user.dart';
import '../widgets/post.dart';
import 'home.dart';

class Timeline extends StatefulWidget {
  const Timeline({super.key, required this.currentUser});
  final User currentUser;

  

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  late List <Post> posts;
  List<String> followingList =[];


  @override
  void initState() {
    
    super.initState();
    getTimeline();
    getFollowing();
  }

  getTimeline() async {
  QuerySnapshot snapshot = await timelineRef
      .doc(widget.currentUser.id)
      .collection('timelinePosts')
      .orderBy('timestamp', descending: true)
      .get();
  List<Post> posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
  setState(() {
    this.posts = posts;
  });
}


  getFollowing() async {
  QuerySnapshot snapshot = await followingRef
      .doc(currentUser?.id)
      .collection('userFollowing')
      .get();
  setState(() {
  followingList = snapshot.docs.map((doc) => doc.id).toList();
});


}


  buildTimeline() {
  // ignore: unnecessary_null_comparison
  if (posts == null) {
    return const CircularProgressIndicator();
  } else if (posts.isEmpty) {
    return buildUsersToFollow();
  } else {
    return ListView(children: posts);
  }
}


  buildUsersToFollow() {
  return StreamBuilder<QuerySnapshot>(
    stream: usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const CircularProgressIndicator();
      }

      List<UserResult> userResults = [];

      snapshot.data!.docs.forEach((doc) {
        User user = User.fromDocument(doc);

        final bool isAuthUser = currentUser?.id == user.id;
        final bool isFollowingUser = followingList.contains(user.id);

        if (isAuthUser || isFollowingUser) {
          return;
        }

        UserResult userResult = UserResult(user);
        userResults.add(userResult);
      });

      return Container(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.person_add,
                    color: Theme.of(context).primaryColor,
                    size: 30.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    "Users to Follow",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 30.0,
                    ),
                  ),
                ],
              ),
            ),
            Column(children: userResults),
          ],
        ),
      );
    },
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: header(context, isAppTitle: true, titleText: ''),
    body: RefreshIndicator(
      onRefresh: () => getTimeline(),
      child: buildTimeline(),
    ),
  );
}
}