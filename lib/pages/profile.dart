import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/edit_profile.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:betterclosetswap/widgets/post.dart';
import 'package:betterclosetswap/widgets/product.dart';
import 'package:betterclosetswap/widgets/header.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({required this.profileId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser!.id;
  String postOrientation = "grid";
  bool isFollowing = false;
  bool isLoading = false;
  int postCount = 0;
  int productCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getProfileProducts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('followers')
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .get();
    setState(() {
      followerCount = snapshot.docs.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((document) => Post.fromDocument(document)).toList();
    });
  }

  getProfileProducts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.profileId)
        .collection('userProducts')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      isLoading = false;
      productCount = snapshot.docs.length;
      products = snapshot.docs.map((document) => Product.fromDocument(document)).toList();
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(currentUserId: currentUserId)));
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
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.blue,
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
    } else if (isFollowing) {
      return buildButton(text: "Unfollow", function: handleUnfollowUser);
    } else {
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }
  }

  void handleUnfollowUser() {
    setState(() {
      isFollowing = false;
      followersRef
          .doc(widget.profileId)
          .collection('userFollowers')
          .doc(currentUserId)
          .delete();
      followingRef
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(widget.profileId)
          .delete();

      // Delete follow activity feed item
      FirebaseFirestore.instance
          .collection('activityFeed')
          .doc(widget.profileId)
          .collection('feedItems')
          .doc(currentUserId)
          .delete();
    });
  }

  void handleFollowUser() {
    setState(() {
      isFollowing = true;
      followersRef
          .doc(widget.profileId)
          .collection('userFollowers')
          .doc(currentUserId)
          .set({});
      followingRef
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(widget.profileId)
          .set({});

      // Create activity feed item for the follow
      FirebaseFirestore.instance
          .collection('activityFeed')
          .doc(widget.profileId)
          .collection('feedItems')
          .doc(currentUserId)
          .set({
        'type': 'follow',
        'username': currentUser!.username,
        'userId': currentUser!.id,
        'postId': '',
        'userProfileImg': currentUser!.photoUrl,
        'commentData': '',
        'timestamp': Timestamp.now(),
        'mediaUrl': '',
      });
    });
  }

  Widget buildProfileHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgress();
        }
        User user = User.fromDocument(snapshot.data!);
        bool isCurrentUserProfile = currentUserId == widget.profileId;
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
                            buildCountColumn("Posts", postCount),
                            buildCountColumn("Followers", followerCount),
                            buildCountColumn("Following", followingCount),
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
              if (isCurrentUserProfile)
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: logout,
                    icon: Icon(Icons.cancel, color: Colors.red),
                    label: Text(
                      "Logout",
                      style: TextStyle(color: Colors.red, fontSize: 20.0),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void logout() {
    googleSignIn.signOut().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    });
  }

  Widget buildProfilePosts() {
    if (isLoading) {
      return CircularProgress();
    }

    return Column(
      children: posts,
    );
  }

  Widget buildProfileProducts() {
    if (isLoading) {
      return CircularProgress();
    }

    return Column(
      children: products,
    );
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          color: postOrientation == "grid" ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => setPostOrientation("grid"),
        ),
        IconButton(
          icon: Icon(Icons.list),
          color: postOrientation == "list" ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => setPostOrientation("list"),
        ),
      ],
    );
  }

  Widget buildProfileDisplay() {
    if (isLoading) {
      return CircularProgress();
    } else if (postOrientation == "grid") {
      return Column(
        children: products,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    } else {
      return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfileDisplay(),
        ],
      ),
    );
  }
}
