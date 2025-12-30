
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleMapsWidget extends StatelessWidget {
  final FirebaseFirestore firestore;
  
  const GoogleMapsWidget({Key? key, required this.firestore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Map not supported on this platform'),
    );
  }
}
