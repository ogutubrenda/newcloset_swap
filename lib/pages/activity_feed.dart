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
  const ActivityFeed({Key? key});

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  Future<List<ActivityFeedItem>> getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .doc(currentUser?.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    List<ActivityFeedItem> feedItems = [];

    for (QueryDocumentSnapshot doc in snapshot.docs) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        print('Activity Feed Item: $data');

        final item = ActivityFeedItem.fromMap(data);

        feedItems.add(item);
      }
    }

    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade600,
      appBar: header(context, titleText: "Activity"),
      body: Container(
        child: FutureBuilder<List<ActivityFeedItem>>(
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgress();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No activity feed items found.');
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  ActivityFeedItem item = snapshot.data![index];
                  return item.build(context);
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String postphotoUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    required this.username,
    required this.userId,
    required this.type,
    required this.postphotoUrl,
    required this.postId,
    required this.userProfileImg,
    required this.commentData,
    required this.timestamp,
  });

  factory ActivityFeedItem.fromMap(Map<String, dynamic> data) {
    return ActivityFeedItem(
      username: data['username'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      postId: data['postId'] as String? ?? '',
      userProfileImg: data['userProfileImg'] as String? ?? '',
      commentData: data['commentData'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      postphotoUrl: data['mediaUrl'] as String? ?? '',
    );
  }

  void showPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(postId: postId, userId: userId),
      ),
    );
  }

  Widget mediaPreview = Container();
  String activityItemText = '';

  void configureMediaPreview(BuildContext context) {
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
                  image: CachedNetworkImageProvider(postphotoUrl),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Container();
    }
    if (type == 'like') {
      activityItemText = "liked your post";
    } else if (type == 'follow') {
      activityItemText = "is following you";
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return ListTile(
      title: GestureDetector(
        onTap: () {},
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
    );
  }
}
