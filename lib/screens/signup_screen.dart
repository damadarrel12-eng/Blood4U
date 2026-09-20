import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final contactController = TextEditingController();

  String? selectedBloodType;

  bool isLoading = false;

  Future<void> signupUser() async {
    setState(() => isLoading = true);

    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.user!.uid)
          .set({
        'email': emailController.text.trim(),
        'bloodType': selectedBloodType,
        'contact': contactController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      setState(() => isLoading = false);

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed")),
      );
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.bloodtype, size: 80, color: Colors.red),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              const SizedBox(height: 10),

              // 🔥 BLOOD TYPE DROPDOWN
              DropdownButtonFormField<String>(
                value: selectedBloodType,
                decoration: const InputDecoration(labelText: "Blood Type"),
                items: [
                  "A+","A-","B+","B-","AB+","AB-","O+","O-"
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBloodType = value;
                  });
                },
              ),

              const SizedBox(height: 10),

              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: "Contact"),
              ),

              const SizedBox(height: 30),

              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: signupUser,
                      child: const Text("Sign Up"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}