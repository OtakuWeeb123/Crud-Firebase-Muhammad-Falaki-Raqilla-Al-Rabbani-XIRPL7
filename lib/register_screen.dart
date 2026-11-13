import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        // 1. Buat akun dengan FirebaseAuth (ditambahkan .trim() untuk mencegah spasi tak sengaja)
        UserCredential creds =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.trim(),
          password: _password.trim(),
        );

        // 2. Simpan data profil ke koleksi 'users' di Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(creds.user!.uid)
            .set({
          'name': _name.trim(),
          'email': _email.trim(),
          'createdAt': Timestamp.now(),
        });

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      } catch (e) {
        // Tampilkan error secara jelas menggunakan Dialog Popup agar bisa dibaca
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gagal Register'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Akun')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (val) =>
                    val!.isEmpty ? 'Nama tidak boleh kosong' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                    val!.isEmpty ? 'Email tidak boleh kosong' : null,
                onSaved: (val) => _email = val!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Password minimal 6 karakter' : null,
                onSaved: (val) => _password = val!,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Daftar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
