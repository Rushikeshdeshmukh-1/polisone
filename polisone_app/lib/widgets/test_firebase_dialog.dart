import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirebaseDialog extends StatelessWidget {
  const TestFirebaseDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Test Firebase Write'),
      content: const Text('Click the button to test if Firebase write works'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              print('🔄 Testing Firebase write...');
              
              final docRef = await FirebaseFirestore.instance
                  .collection('test_collection')
                  .add({
                'message': 'Test write',
                'timestamp': FieldValue.serverTimestamp(),
              });
              
              print('✅ Test document created with ID: ${docRef.id}');
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Success! Document ID: ${docRef.id}'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              print('❌ Error: $e');
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Test Write'),
        ),
      ],
    );
  }
}
