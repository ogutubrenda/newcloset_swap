import 'package:flutter/material.dart';
import 'package:betterclosetswap/widgets/header.dart';
import 'package:betterclosetswap/widgets/progress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Timeline extends StatefulWidget {
  const Timeline({super.key});

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true, titleText: ''),
      body: CircularProgress(),
    );
  }
}