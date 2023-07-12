import 'package:flutter/material.dart';
AppBar header(context, {bool  isAppTitle = false, required String titleText, removeBackButton = false}){
  return AppBar(
    automaticallyImplyLeading: !removeBackButton,
    title: Text(
     isAppTitle ? "ClosetSwap" : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle? "Signatra" : "",
        fontSize: isAppTitle? 30.0 : 20,
      ),
      overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).hintColor,
  );
}