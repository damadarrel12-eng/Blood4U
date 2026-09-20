import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String uid;

  const ChatScreen({super.key, required this.name, required this.uid});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  void sendMessage() {
    if (controller.text.isEmpty) return;

    FirebaseFirestore.instance.collection('messages').add({
      "text": controller.text,
      "sender": currentUser!.uid,
      "receiver": widget.uid,
      "timestamp": FieldValue.serverTimestamp(),
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),

      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView(
                  children: messages.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final isMe = data['sender'] == currentUser!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(10),
                        color: isMe ? Colors.blue : Colors.grey,
                        child: Text(data['text']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(child: TextField(controller: controller)),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
}