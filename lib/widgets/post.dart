import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class Posts extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Posts({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
  });

  factory Posts.fromDocument(DocumentSnapshot document) {
    return Posts(
      postId: document['postId'],
      ownerId: document['ownerId'],
      username: document['username'],
      location: document['location'],
      description: document['description'],
      mediaUrl: document['mediaUrl'],
      likes: document['likes'],
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
  _PostsState createState() => _PostsState(
        postId: postId,
        ownerId: ownerId,
        username: username,
        location: location,
        description: description,
        mediaUrl: mediaUrl,
        likes: likes,
        likeCount: getLikeCount(),
      );
}

class _PostsState extends State<Posts> {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;

  _PostsState({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
    required this.likeCount,
  });
  buildPostHeader(){
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return CircularProgress();
        }
        User user = User.fromDocument(snapshot.data!);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,),
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
              onPressed: ()=> print('deleting post'),
              icon: Icon(Icons.more_vert),
            ),
        );
      }
    );
  }
  buildPostImage(){
    return GestureDetector(
      onDoubleTap: () => print('liking post'),
      child: Stack(alignment: Alignment.center,
      children: <Widget>[
        Image.network(mediaUrl),

      ],)
    );
  }
  buildPostFooter(){
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
          Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
          GestureDetector(
            onTap: ()=> print('liking post'),
          child: Icon( Icons.favorite_border,
          size: 28.0,
          color: Colors.pink.shade700)
          ),
          Padding(padding: EdgeInsets.only(right: 20.0)),
          GestureDetector(
            onTap: ()=> print('showing comments'),
          child: Icon( Icons.chat,
          size: 28.0,
          color: Colors.blueGrey),
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
                  style: TextStyle(color: Colors.black,
                  fontWeight: FontWeight.bold,) 
                ),
              ),
              Expanded(child: Text(description),)
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 20),
                child: Text(
                  "$username",
                  style: TextStyle(color: Colors.black,
                  fontWeight: FontWeight.bold,) 
                ),
              ),
              Expanded(child: Text(description),)
            ],
          ),
        
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
