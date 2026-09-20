import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class DonorScreen extends StatelessWidget {
  DonorScreen({super.key});

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donors Nearby")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView(
            children: users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              // ❌ Don't show yourself
              if (data['uid'] == currentUser?.uid) return const SizedBox();

              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? ""),
                  subtitle: Text("Blood: ${data['bloodType']}"),

                  trailing: IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            name: data['name'],
                            uid: data['uid'],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}