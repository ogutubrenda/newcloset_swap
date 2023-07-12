import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/pages/post_screen.dart';
import 'package:betterclosetswap/pages/profile.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:betterclosetswap/widgets/header.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  const ActivityFeed({super.key});

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed()async{
    QuerySnapshot snapshot= await activityFeedRef
    .doc(currentUser!.id)
    .collection('FeedItems')
    .orderBy('timestamp', descending:true)
    .limit(50)
    .get();
    List<ActivityFeedItem> feedItems = [];
    snapshot.docs.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
      //print('Activity Feed Item: ${doc.data}');
    }
    );

    
  return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Colors.orange,
  appBar: header(context, titleText: "Activity Feed"), // Add a comma after context
  body: Container(
    child: FutureBuilder(
      future: getActivityFeed(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgress();
          }
          return ListView(
            children: snapshot.data as List<Widget>,
            );
        },
      )
    ),
    );
  }
}

Widget mediaPreview = Container();
String activityItemText= '';

// ignore: must_be_immutable
class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // 'like', 'follow', 'comment'
  final String photoUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    required this.username,
    required this.userId,
    required this.type,
    required this.photoUrl,
    required this.postId,
    required this.userProfileImg,
    required this.commentData,
    required this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
      photoUrl: doc['photoUrl'],
    );
  }

  showPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userid: userId,
        ),
      ),
    );
  }

  configureMediaPreview(BuildContext context) {
    if (type == "like" || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(photoUrl),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }
  }

  String activityItemText = '';

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    if (type == 'like') {
      activityItemText = "liked your post";
    } else if (type == 'follow') {
      activityItemText = "is following you";
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ' $activityItemText',
                  ),
                ],
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }

  void showProfile(BuildContext context, {required String profileId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profile(profileId: profileId),
      ),
    );
  }
}



