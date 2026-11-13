import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_edit_transaction_screen.dart';
import 'login_screen.dart';
import 'transaction_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = "Pengguna";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  void _fetchUserName() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc.get('name') ?? "Pengguna";
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, $userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistik Total & Ringkasan Transaksi
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .where('userId', isEqualTo: user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }

              double totalPemasukan = 0;
              double totalPengeluaran = 0;

              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                double amount = (data['amount'] ?? 0).toDouble();
                if (data['type'] == 'Pemasukan') {
                  totalPemasukan += amount;
                } else {
                  totalPengeluaran += amount;
                }
              }

              double saldoAkhir = totalPemasukan - totalPengeluaran;

              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Saldo Keuangan',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(currencyFormatter.format(saldoAkhir),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pemasukan',
                                style: TextStyle(
                                    color: Colors.greenAccent, fontSize: 12)),
                            Text(currencyFormatter.format(totalPemasukan),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pengeluaran',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12)),
                            Text(currencyFormatter.format(totalPengeluaran),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Riwayat Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          // Riwayat Transaksi Real-time dengan StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Belum ada catatan transaksi.'));
                }

                var transactions = snapshot.data!.docs
                    .map((doc) => TransactionModel.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isPemasukan = tx.type == 'Pemasukan';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPemasukan
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            isPemasukan
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isPemasukan ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(tx.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(tx.date)),
                        trailing: Text(
                          currencyFormatter.format(tx.amount),
                          style: TextStyle(
                            color: isPemasukan ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          // Edit / Detail Transaksi
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditTransactionScreen(transaction: tx),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddEditTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
