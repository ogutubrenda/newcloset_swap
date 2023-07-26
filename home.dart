import 'package:betterclosetswap/pages/activity_feed.dart';
import 'package:betterclosetswap/pages/cart.dart';
import 'package:betterclosetswap/pages/home_page.dart';
import 'package:betterclosetswap/pages/products.dart';
import 'package:betterclosetswap/pages/profile.dart';
import 'package:betterclosetswap/pages/search.dart';
import 'package:betterclosetswap/pages/upload.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:betterclosetswap/pages/create_account.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:betterclosetswap/models/user.dart';



final GoogleSignIn googleSignIn = GoogleSignIn();
final firebase_storage.Reference storageRef =
    firebase_storage.FirebaseStorage.instance.ref();
final usersRef = FirebaseFirestore.instance.collection('users');

final postsRef = FirebaseFirestore.instance.collection('posts');
final productsRef = FirebaseFirestore.instance.collection('products');
final commentsRef = FirebaseFirestore.instance.collection('comments');
final activityFeedRef = FirebaseFirestore.instance.collection('feed');
final followersRef = FirebaseFirestore.instance.collection('followers');
final cartRef= FirebaseFirestore.instance.collection('cart');
final followingRef = FirebaseFirestore.instance.collection('following');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
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

  handleSignIn(GoogleSignInAccount? account ) async {
    if (account != null) {
    await   createUserInFirestore();
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
  if (user == null) {
    // User is null, handle the error
    print('Error: User is null.');
    return;
  }

  DocumentSnapshot document = await usersRef.doc(user.id).get();
  if (!document.exists) {
    final username = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAccount()),
    );
    if (username == null) {
      // Username is null, handle the error
      print('Error: Username is null.');
      return;
    }

    usersRef.doc(user.id).set({
      "id": user.id,
      "username": username,
      "photoUrl": user.photoUrl,
      "email": user.email,
      "displayName": user.displayName,
      "bio": "",
      "timestamp": timestamp,
    });

    document = await usersRef.doc(user.id).get();
  }

  if (!document.exists) {
    // Document doesn't exist, handle the error
    print('Error: Document does not exist.');
    return;
  }

  currentUser = User.fromDocument(document);

  setState(() {
    isAuth = true;
  });
}


  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() async {
  try {
    await googleSignIn.signIn();
  } catch (error) {
    print('Error signing in: $error');
  }
}


  logout() {
    googleSignIn.signOut().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CreateAccount()),
      );
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    if (currentUser == null) {
      // Handle case when currentUser is null (e.g., show loading indicator)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        body: PageView(
          children: <Widget>[
            
            //HomePage(),
            ActivityFeed(),
            Upload(currentUser: currentUser!),
            Products(currentUser: currentUser!),
            Cart(currentUser: currentUser!),
            Search(),

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
          items: const [
            //BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
            BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
            BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart)),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded)),
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
        decoration: const BoxDecoration(
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
            const Text(
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
                decoration: const BoxDecoration(
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