import 'package:flutter/material.dart';
import 'create_sos_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SOSAlertButton extends StatelessWidget {
  final FirebaseFirestore firestore;

  const SOSAlertButton({Key? key, required this.firestore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CreateSOSDialog(firestore: firestore),
        );
      },
      backgroundColor: Colors.red,
      icon: const Icon(Icons.report_problem, color: Colors.white),
      label: const Text(
        'SOS EMERGENCY',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
