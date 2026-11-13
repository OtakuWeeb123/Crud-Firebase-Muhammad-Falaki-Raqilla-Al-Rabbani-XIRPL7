import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'transaction_model.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionScreen({Key? key, this.transaction})
      : super(key: key);

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _amount;
  late String _type;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _title = widget.transaction?.title ?? '';
    _amount = widget.transaction?.amount ?? 0.0;
    _type = widget.transaction?.type ?? 'Pemasukan';
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;

      try {
        if (widget.transaction == null) {
          // Tambah transaksi baru
          await FirebaseFirestore.instance.collection('transactions').add({
            'userId': user!.uid,
            'title': _title,
            'amount': _amount,
            'type': _type,
            'date': Timestamp.now(),
          });
        } else {
          // Edit transaksi yang ada
          await FirebaseFirestore.instance
              .collection('transactions')
              .doc(widget.transaction!.id)
              .update({
            'title': _title,
            'amount': _amount,
            'type': _type,
          });
        }
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteTransaction() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus catatan transaksi ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              setState(() => _isLoading = true);
              await FirebaseFirestore.instance
                  .collection('transactions')
                  .doc(widget.transaction!.id)
                  .delete();
              if (!mounted) return;
              Navigator.pop(context); // Kembali ke dasbor
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Detail & Edit Transaksi' : 'Tambah Transaksi'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Judul Transaksi'),
                validator: (value) =>
                    value!.isEmpty ? 'Judul tidak boleh kosong' : null,
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _amount == 0.0 ? '' : _amount.toString(),
                decoration:
                    const InputDecoration(labelText: 'Nominal Angka (Rp)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Masukkan angka nominal yang valid';
                  }
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: ['Pemasukan', 'Pengeluaran']
                    .map((label) =>
                        DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
                decoration: const InputDecoration(labelText: 'Tipe Transaksi'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Simpan Perubahan' : 'Tambah Transaksi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
