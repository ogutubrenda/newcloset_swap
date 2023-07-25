import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  late final String postId;
  late final String ownerId;
  late final String username;
  late final String location;
  late final String description;
  late final String mediaUrl;
  late final Map likes;
  //int likeCount;


  PostModel({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
    //required this.likeCount,
  });

  

  factory PostModel.fromDocument(DocumentSnapshot document) {
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

    return PostModel(
      postId: data?['postId'],
      ownerId: data?['ownerId'],
      username: data?['username'],
      location: data?['location'],
      description: data?['description'],
      mediaUrl: data?['mediaUrl'],
      likes: data?['likes'] ?? {},
      //likeCount: getLikeCount(data?['likes']),
    );
  }

  get userId => null;
}
 
