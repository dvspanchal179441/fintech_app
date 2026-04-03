import 'package:flutter/material.dart';
import '../models/models.dart';

class GiftCardVaultScreen extends StatefulWidget {
  const GiftCardVaultScreen({super.key});

  @override
  State<GiftCardVaultScreen> createState() => _GiftCardVaultScreenState();
}

class _GiftCardVaultScreenState extends State<GiftCardVaultScreen> {
  final List<GiftCard> _mockVault = [
    GiftCard(
      id: "g1",
      provider: "Amazon",
      claimCode: "AMZN-1928-ABCD",
      balance: 1500.0,
      expiryDate: DateTime.now().add(const Duration(days: 120)),
    ),
    GiftCard(
      id: "g2",
      provider: "Flipkart",
      claimCode: "FLIP-ZZX2-9901",
      balance: 500.0,
      expiryDate: DateTime.now().add(const Duration(days: 45)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Card Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final newGiftCard = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddGiftCardScreen()),
              );

              if (newGiftCard != null && newGiftCard is GiftCard) {
                setState(() {
                  _mockVault.add(newGiftCard);
                });
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Gift card parsed & added securely!")),
                  );
                }
              }
            },
          )
        ],
      ),
      body: _mockVault.isEmpty
          ? const Center(child: Text("No gift cards in vault yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _mockVault.length,
              itemBuilder: (context, index) {
                final card = _mockVault[index];
                return Dismissible(
                  key: Key(card.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      _mockVault.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gift card deleted')));
                  },
                  child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      card.provider.toLowerCase() == 'amazon' ? Icons.shopping_cart : Icons.shop_two,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(card.provider, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Code: ${card.claimCode}", style: const TextStyle(fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Text("Expires: ${card.expiryDate.day}/${card.expiryDate.month}/${card.expiryDate.year}"),
                      ],
                    ),
                    trailing: Text(
                      "₹${card.balance.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                    ),
                  ),
                ));
              },
            ),
    );
  }
}

class AddGiftCardScreen extends StatefulWidget {
  const AddGiftCardScreen({super.key});

  @override
  State<AddGiftCardScreen> createState() => _AddGiftCardScreenState();
}

class _AddGiftCardScreenState extends State<AddGiftCardScreen> {
  String provider = '';
  String claimCode = '';
  String balanceStr = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Gift Card')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Provider (e.g. Amazon, Myntra)", border: OutlineInputBorder()),
              onChanged: (val) => provider = val,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: "Claim Code", border: OutlineInputBorder()),
              onChanged: (val) => claimCode = val,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: "Balance Amount", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (val) => balanceStr = val,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (provider.isNotEmpty && claimCode.isNotEmpty) {
                  final newCard = GiftCard(
                    id: "g${DateTime.now().millisecondsSinceEpoch}",
                    provider: provider,
                    claimCode: claimCode,
                    balance: double.tryParse(balanceStr) ?? 0.0,
                    expiryDate: DateTime.now().add(const Duration(days: 365)), // default 1 year
                  );
                  Navigator.pop(context, newCard);
                }
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Save to Vault", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
