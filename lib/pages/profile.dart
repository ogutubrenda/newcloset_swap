

import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/edit_profile.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:betterclosetswap/widgets/post.dart';
import 'package:betterclosetswap/widgets/header.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({required this.profileId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser!.id;
  bool isLoading = false;
  int postCount = 0;
  List<Posts> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
  }

  Future<void> getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot<Map<String, dynamic>> snapshot = await postsRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      isLoading = false;
      postCount = snapshot.size;
      posts = snapshot.docs
          .map((document) => Posts.fromDocument(document))
          .toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        )
      ],
    );
  }

  void editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  Container buildButton({required String text, required Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: ElevatedButton(
        onPressed: () => function(),
        child: Container(
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(
              color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  Widget buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(
        text: "Edit Profile",
        function: editProfile,
      );
    } else {
      return Container();
    }
  }

  Widget buildProfileHeader() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgress();
        }

        User user = User.fromDocument(snapshot.data!);

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", 0),
                            buildCountColumn("following", 0),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(user.bio),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildProfilePosts() {
  if (isLoading) {
    return CircularProgress();
  } else {
    return Column(
      children: posts.map((post) => Posts(
        postId: post.postId,
        ownerId: post.ownerId,
        username: post.username,
        location: post.location,
        description: post.description,
        mediaUrl: post.mediaUrl,
        likes: post.likes,
      )).toList(),
    );
  }
}







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}

