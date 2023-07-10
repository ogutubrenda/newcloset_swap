//import 'dart:html';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/widgets/progress.dart';

import '../models/user.dart';
class Search extends StatefulWidget {
  const Search(Future<QuerySnapshot<Object?>> searchResultsFuture, {super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController =TextEditingController();
late Future<QuerySnapshot> searchResultsFuture;

handleSearch(String query){
  Future<QuerySnapshot>users =usersRef
  .where("displayName",isGreaterThanOrEqualTo: query)
  .get();
  setState((){
    searchResultsFuture = users;

  });
}
clearSearch(){
  searchController.clear();
}

  AppBar buidSearchField(){
return AppBar(
  backgroundColor: Colors.white,
  title: TextFormField(
    controller: searchController,
    decoration: InputDecoration(
      hintText: "Search for a user",
      filled: true,
      prefixIcon: Icon(
        Icons.account_box,
        size: 28.0,
      ),
      suffixIcon: IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => clearSearch,
      ),
    ),
    onFieldSubmitted: handleSearch,
  ),
);


  }

  Container buildNoContent(){
    final Orientation orientation =MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child:  Center(
          child: ListView(
            shrinkWrap: true,
            children:<Widget>[
              SvgPicture.asset('assets/image2vector.svg', 
              height: orientation == Orientation.portrait?300.0 : 200.0),
              Text("Find user", textAlign: TextAlign.center, style:
              TextStyle(
                 color: Colors.amber,
                 fontStyle: FontStyle.italic,
                 fontWeight: FontWeight.w600,
                 fontSize: 60.0,
                 )
              )
            ],)
        ),)

    );

  }
  buildSearchResults(){
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if(!snapshot.hasData){
          return CircularProgress();
        }
        List<UserResult> searchResults =[];
        snapshot.data?.docs.forEach((document){
          User user = User.fromDocument(document);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);

        }
        );
        return ListView(
          children: searchResults,
        );
      }
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buidSearchField(),
      body: searchResultsFuture == null? buildNoContent(): buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);
  //const UserResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(children: <Widget>[
        GestureDetector(
          onTap:()=>print ('tapped'),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            ),
            title: Text(user.displayName, style: TextStyle(color:Colors.white, fontWeight: FontWeight.bold,),),
            subtitle: Text(user.username, style: TextStyle(color: Colors.white,)),
            ),
          ),
           Divider(
            height:2.0,
            color: Colors.white54,
           ),
      ],)
    );
  }
}