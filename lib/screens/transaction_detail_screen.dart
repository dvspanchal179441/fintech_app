import 'package:flutter/material.dart';
import '../models/models.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final List<ExtendedTransaction> _transactionsList = [
    ExtendedTransaction(
      transactionId: "TXN-101",
      note: "Team lunch",
    ),
    ExtendedTransaction(
      transactionId: "TXN-102",
      note: null,
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              // Create a dummy new transaction to edit
              final newTxn = ExtendedTransaction(
                transactionId: "TXN-${DateTime.now().millisecondsSinceEpoch}",
              );
              
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(transaction: newTxn),
                ),
              );

              if (result != null && result is ExtendedTransaction) {
                setState(() {
                  _transactionsList.insert(0, result);
                });
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Transaction added successfully!')),
                  );
                }
              }
            },
          )
        ],
      ),
      body: _transactionsList.isEmpty
          ? const Center(child: Text("No transactions available."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _transactionsList.length,
              itemBuilder: (context, index) {
                final txn = _transactionsList[index];
                return Dismissible(
                  key: Key(txn.transactionId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      _transactionsList.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
                  },
                  child: Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, size: 36),
                    title: Text(txn.transactionId, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(txn.note ?? "No notes added"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      // Edit existing transaction
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(transaction: txn),
                        ),
                      );
                      if (result != null && result is ExtendedTransaction) {
                        setState(() {
                          _transactionsList[index] = result;
                        });
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Transaction updated!')),
                          );
                        }
                      }
                    },
                  ),
                ));
              },
            ),
    );
  }
}

class TransactionDetailScreen extends StatefulWidget {
  final ExtendedTransaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.transaction.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Txn ID: ${widget.transaction.transactionId}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            const Text("Amount Paid", style: TextStyle(fontSize: 16)),
            const Text("₹1,240.00", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 30),

            const Text("Notes & Tags", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Add specific notes about this transfer...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                widget.transaction.note = val;
              },
            ),
            const SizedBox(height: 30),
            
            const Text("Receipt Attachment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Simulating Image Picker...")));
              },
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                child: widget.transaction.attachmentPath != null 
                  ? const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 40, color: Colors.black54),
                        SizedBox(height: 8),
                        Text("Tap to attach receipt photo", style: TextStyle(color: Colors.black54))
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Return the modified transaction
          Navigator.pop(context, widget.transaction);
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
