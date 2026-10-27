import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/blood_request_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key, FirestoreService? firestoreService})
      : _firestore = firestoreService;

  final FirestoreService? _firestore;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late final FirestoreService _firestore =
      widget._firestore ?? FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final _areaController = TextEditingController();
  final _detailsController = TextEditingController();
  String? _bloodType;
  bool _saving = false;

  @override
  void dispose() {
    _hospitalController.dispose();
    _areaController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _showRequestForm() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Post a blood request'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _bloodType,
                    decoration: const InputDecoration(labelText: 'Blood type'),
                    items: UserModel.bloodTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setDialogState(() => _bloodType = value),
                    validator: (value) =>
                        value == null ? 'Choose a blood type.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hospitalController,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Hospital or collection centre',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _areaController,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Area'),
                    validator: _required,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Additional details (optional)',
                      helperText:
                          'Do not include patient names, phone numbers, or diagnoses.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () => _submitRequest(dialogContext, setDialogState),
              child: Text(_saving ? 'Posting…' : 'Post request'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'This field is required.'
      : null;

  Future<void> _submitRequest(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    final requesterId = FirebaseAuth.instance.currentUser?.uid;
    if (requesterId == null || _bloodType == null) return;

    setState(() => _saving = true);
    setDialogState(() {});
    try {
      await _firestore.createBloodRequest(
        requesterId: requesterId,
        bloodType: _bloodType!,
        hospitalName: _hospitalController.text,
        area: _areaController.text,
        details: _detailsController.text,
      );
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      _hospitalController.clear();
      _areaController.clear();
      _detailsController.clear();
      setState(() => _bloodType = null);
      _showMessage('Your request is now visible to signed-in users.');
    } catch (_) {
      if (mounted) _showMessage('The request could not be posted. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
      if (dialogContext.mounted) setDialogState(() {});
    }
  }

  Future<void> _closeRequest(BloodRequest request) async {
    try {
      await _firestore.closeBloodRequest(request.id);
      _showMessage('Request closed.');
    } catch (_) {
      _showMessage('The request could not be closed. Try again.');
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
        body: Center(child: Text('Sign in to view blood requests.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Blood requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _showRequestForm,
        icon: const Icon(Icons.add),
        label: const Text('Post request'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Requests help people connect with donors. For urgent medical care, contact local emergency services or a hospital directly.',
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BloodRequest>>(
              stream: _firestore.watchOpenBloodRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Requests could not be loaded. Try again later.'),
                    ),
                  );
                }
                final requests = snapshot.data ?? const <BloodRequest>[];
                if (requests.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'There are no open requests right now. You can post one when needed.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final isMine = request.requesterId == uid;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                child: Text(request.bloodType),
                              ),
                              title: Text(request.hospitalName),
                              subtitle: Text(
                                '${request.area}\n${request.details.isEmpty ? 'No additional details' : request.details}',
                              ),
                              isThreeLine: true,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isMine)
                                    TextButton.icon(
                                      onPressed: () => _closeRequest(request),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Close request'),
                                    )
                                  else
                                    FilledButton.tonalIcon(
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ChatScreen(
                                            name: 'Request contact',
                                            uid: request.requesterId,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.chat_bubble_outline),
                                      label: const Text('Offer help'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
