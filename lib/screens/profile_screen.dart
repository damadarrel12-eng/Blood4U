import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirestoreService();
  final _areaController = TextEditingController();
  bool _updatingAvailability = false;
  bool _signingOut = false;

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _setAvailability(UserModel profile, bool available) async {
    if (available && _areaController.text.trim().isEmpty) {
      _showMessage('Add your area before appearing in the donor list.');
      return;
    }

    setState(() => _updatingAvailability = true);
    try {
      await _firestore.setDonorAvailability(
        profile: profile,
        available: available,
        area: _areaController.text,
      );
      if (mounted) {
        _showMessage(
          available
              ? 'You are now listed as an available donor.'
              : 'You are no longer listed as available.',
        );
      }
    } catch (_) {
      _showMessage('Your availability could not be updated. Try again later.');
    } finally {
      if (mounted) setState(() => _updatingAvailability = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await AuthService().logout();
    } catch (_) {
      _showMessage('Could not sign out. Try again.');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: StreamBuilder<UserModel?>(
        stream: _firestore.watchProfile(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ProfileMessage(
              message: 'Your profile could not be loaded.',
              icon: Icons.cloud_off,
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return _ProfileMissing(onSignOut: _signOut);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Text(
                  profile.bloodType,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _ProfileDetail(label: 'Email', value: profile.email),
              _ProfileDetail(label: 'Contact number', value: profile.contact),
              _ProfileDetail(label: 'Blood type', value: profile.bloodType),
              const SizedBox(height: 24),
              Text('Donor availability',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'When switched on, your name, blood type, and area are visible to signed-in users. Your email and phone number stay private.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _areaController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your area',
                  hintText: 'For example, neighbourhood or town',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: profile.isDonorAvailable,
                title: const Text('Show me in the donor list'),
                subtitle: Text(
                  profile.isDonorAvailable
                      ? 'You are currently visible to signed-in users.'
                      : 'You are currently hidden from the donor list.',
                ),
                onChanged: _updatingAvailability
                    ? null
                    : (value) => _setAvailability(profile, value),
              ),
              if (_updatingAvailability)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _signingOut ? null : _signOut,
                icon: _signingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(_signingOut ? 'Signing out…' : 'Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 44), const SizedBox(height: 12), Text(message)],
        ),
      ),
    );
  }
}

class _ProfileMissing extends StatelessWidget {
  const _ProfileMissing({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 44),
            const SizedBox(height: 12),
            const Text(
              'This account does not have a Blood4U profile yet. Sign out and contact the project owner for help.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
