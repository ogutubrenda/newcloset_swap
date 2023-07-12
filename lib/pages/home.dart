import 'package:betterclosetswap/pages/products.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:betterclosetswap/pages/activity_feed.dart';
import 'package:betterclosetswap/pages/create_account.dart';
import 'package:betterclosetswap/pages/profile.dart';
import 'package:betterclosetswap/pages/search.dart';
import 'package:betterclosetswap/pages/timeline.dart';
import 'package:betterclosetswap/pages/upload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:betterclosetswap/models/user.dart';

import 'package:betterclosetswap/pages/create_account.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final firebase_storage.Reference storageRef =
    firebase_storage.FirebaseStorage.instance.ref();
final usersRef = FirebaseFirestore.instance.collection('users');
final postsRef = FirebaseFirestore.instance.collection('posts');
final productsRef = FirebaseFirestore.instance.collection('products');
final DateTime timestamp = DateTime.now();
User? currentUser;


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  late PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account!);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account!);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  handleSignIn(GoogleSignInAccount? account) {
    if (account != null) {
      createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    final GoogleSignInAccount? user = googleSignIn.currentUser;
    DocumentSnapshot document = await usersRef.doc(user?.id).get();
    if (!document.exists) {
      final username = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateAccount()),
      );

      usersRef.doc(user?.id).set({
        "id": user?.id,
        "username": username,
        "photoUrl": user?.photoUrl,
        "email": user?.email,
        "displayName": user?.displayName,
        "bio": "",
        "timestamp": timestamp,
      });

      document = await usersRef.doc(user?.id).get();
    }

    currentUser = User.fromDocument(document);
    print(currentUser);
    print(currentUser!.username);

    setState(() {
      isAuth = true;
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CreateAccount()),
      );
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    if (currentUser == null) {
      // Handle case when currentUser is null (e.g., show loading indicator)
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        body: PageView(
          children: <Widget>[
            ElevatedButton(
              child: Text('Logout'),
              onPressed: () => logout(),
            ),
            ActivityFeed(),
            //Search(),
            Upload(currentUser: currentUser!),
            Products(currentUser: currentUser!),
            Profile(profileId: currentUser!.id),
          ],
          controller: pageController,
          onPageChanged: onPageChanged,
          physics: NeverScrollableScrollPhysics(),
        ),
        bottomNavigationBar: CupertinoTabBar(
          currentIndex: pageIndex,
          onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
            BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
            BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
          ],
        ),
      );
    }
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.amberAccent,
              Colors.blueGrey,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'ClosetSwap',
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 50.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/google_signin.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
