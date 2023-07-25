import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  late final String id;
  late final String username;
  late final String email;
  late final String photoUrl;
  late final String displayName;
  late final String bio;
  //late final String password;
 
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.displayName,
    required this.bio,
    //required this.password,
   
  });

  factory User.fromDocument(DocumentSnapshot document) {
    return User(
      id: document['id'],
      email: document['email'],
      username: document['username'],
      photoUrl: document['photoUrl'],
      bio: document['bio'],
      displayName: document['displayName'],
      //password: document['password'],
    
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "id": id,
      "email": email,
      "photoUrl": photoUrl,
      "bio": bio,
      "displayName": displayName,
      //"password": password,
     
    };
  }

  get userId => null;
}
