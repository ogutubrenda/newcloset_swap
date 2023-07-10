import 'package:flutter/material.dart';
  Container CircularProgress(){
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.only(top:10),
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.amber),
    )
  );
}
Container LinearProgress(){
  return Container(
    padding: EdgeInsets.only(bottom:10),
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.amber),
    )
  );
}