import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .get(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              const SizedBox(height: 20),

              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.red,
                child: Text(
                  data['bloodType'] ?? "",
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  data['name'] ?? "",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 30),

              buildTile("Email", data['email']),
              buildTile("Contact", data['contact']),
              buildTile("Blood Type", data['bloodType']),

            ],
          );
        },
      ),
    );
  }

  Widget buildTile(String title, String? value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value ?? ""),
      ),
    );
  }
}