import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class DonorScreen extends StatelessWidget {
  DonorScreen({super.key, FirestoreService? firestoreService})
      : _firestore = firestoreService ?? FirestoreService();

  final FirestoreService _firestore;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view available donors.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Available donors')),
      body: Column(
        children: [
          const _PrivacyNote(),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firestore.watchAvailableDonors(
                currentUserId: currentUserId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _EmptyState(
                    icon: Icons.cloud_off,
                    message: 'Donors could not be loaded. Try again later.',
                  );
                }

                final donors = snapshot.data ?? const <UserModel>[];
                if (donors.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.people_outline,
                    message:
                        'No one is listed right now. You can opt in from your profile.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: donors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _DonorCard(
                    donor: donors[index],
                    onChat: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(
                          name: donors[index].name,
                          uid: donors[index].uid,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Only people who opted in appear here. Contact details are not shown.',
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  const _DonorCard({required this.donor, required this.onChat});

  final UserModel donor;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: Text(donor.bloodType),
        ),
        title: Text(donor.name),
        subtitle: Text(donor.area.isEmpty ? 'Area not provided' : donor.area),
        trailing: IconButton(
          tooltip: 'Message ${donor.name}',
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: onChat,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
