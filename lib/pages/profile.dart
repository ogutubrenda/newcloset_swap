import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/edit_profile.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:betterclosetswap/widgets/header.dart';
import 'package:flutter_svg/svg.dart';

import '../widgets/post.dart';
import '../widgets/post_tile.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({required this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final String currentUserId = currentUser!.id;
  String postOrientation = "grid";

  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  Future<void> checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  Future<void> getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .get();
    setState(() {
      followerCount = snapshot.docs.length;
    });
  }

  Future<void> getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }

  Future<void> getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: const TextStyle(
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
        builder: (context) => EditProfile(currentUserId: currentUserId),
      ),
    );
  }

  Container buildButton({required String text, required Function function}) {
    return Container(
      padding: const EdgeInsets.only(top: 2.0),
      child: TextButton(
        onPressed: () => function(),
        child: Container(
          width: 250.0,
          height: 27.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
  } else if (isFollowing) {
    return buildButton(text: "Unfollow", function: handleUnfollowUser);
  } else if (!isFollowing) {
    return buildButton(
      text: "Follow",
      function: handleFollowUser,
    );
  }
  // Add a default return statement
  return const SizedBox.shrink();
}


  void handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    // Remove follower
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // Remove following
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // Delete activity feed item for them
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  void handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    // Make auth user a follower of another user (update their followers collection)
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .set({});
    // Put that user on your following collection (update your following collection)
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .set({});
    // Add activity feed item for that user to notify about new followers (us)
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .set({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser?.username,
      "userId": currentUserId,
      "userProfileImg": currentUser?.photoUrl,
      "timestamp": timestamp,
    });
  }

  Widget buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgress();
        }
        User user = User.fromDocument(snapshot.data!);
        return Padding(
          padding: const EdgeInsets.all(16.0),
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
                            buildCountColumn("followers", followerCount),
                            buildCountColumn("following", followingCount),
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
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  )),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    user.bio,
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget buildProfilePosts() {
    if (isLoading) {
      return CircularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/image2vector/no_content.svg'),
            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 38.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts.map((post) => PostTile(post)).toList(),
      );
    }
    return const SizedBox.shrink();
  }

  void setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  Widget buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setPostOrientation("grid"),
          icon: const Icon(Icons.grid_on),
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostOrientation("list"),
          icon: const Icon(Icons.list),
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          const Divider(),
          buildTogglePostOrientation(),
          const Divider(height: 0.0),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
