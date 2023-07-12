import 'package:betterclosetswap/models/user.dart';
import 'package:betterclosetswap/pages/edit_profile.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:betterclosetswap/widgets/header.dart';
class Profile extends StatefulWidget {
  final String profileId;

  Profile({required this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final String currentUserId = currentUser!.id;


buildCountColumn(String label, int count){
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Text(
        count.toString(),
        style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold,), 
      ),
      Container(
        margin: const EdgeInsets.only(top : 4.0),
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
editProfile(){
  Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(currentUserId: currentUserId)));

}
Container buildButton({required String text, required Function function}){
  return Container(
    padding: const EdgeInsets.only(top: 2.0),
    child: ElevatedButton(
      onPressed: () => function(), 
      child: Container(
        width: 250.0,
        height: 27.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blue,
          border: Border.all(
            color: Colors.blue,
          ),
          borderRadius: BorderRadius.circular(5.0)
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ) ),
      ),),
  );
}
buildProfileButton(){
  bool isProfileOwner = currentUserId == widget.profileId;
  if(isProfileOwner){
    return buildButton(
      text: "Edit Profile",
      function: editProfile,
    );
  }
}

  buildProfileHeader(){
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
                        buildCountColumn("posts", 0),
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
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                   user.username,
                   style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                   ))
              ),
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
                   )
              ),
              ]
            ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),

        ],
      ),
    );
  }
}
