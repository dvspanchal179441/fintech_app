import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class GiftCardVaultScreen extends StatefulWidget {
  const GiftCardVaultScreen({super.key});

  @override
  State<GiftCardVaultScreen> createState() => _GiftCardVaultScreenState();
}

class _GiftCardVaultScreenState extends State<GiftCardVaultScreen> {
  List<GiftCard> _vault = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    final saved = await LocalStorageService.loadGiftCards();
    setState(() {
      _vault = saved.map((e) => GiftCard(
        id: e['id'] ?? '',
        provider: e['provider'] ?? '',
        claimCode: e['claimCode'] ?? '',
        balance: double.tryParse(e['balance']?.toString() ?? '0') ?? 0.0,
        expiryDate: DateTime.tryParse(e['expiryDate'] ?? '') ?? DateTime.now(),
      )).toList();
      _loading = false;
    });
  }

  Future<void> _saveVault() async {
    final list = _vault.map((e) => {
      'id': e.id,
      'provider': e.provider,
      'claimCode': e.claimCode,
      'balance': e.balance,
      'expiryDate': e.expiryDate.toIso8601String(),
    }).toList();
    await LocalStorageService.saveGiftCards(list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gift Card Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final newGiftCard = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddGiftCardScreen()),
              );

              if (newGiftCard != null && newGiftCard is GiftCard) {
                setState(() {
                  _vault.add(newGiftCard);
                });
                await _saveVault();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Gift card added to vault")),
                  );
                }
              }
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _vault.isEmpty
              ? const Center(child: Text("No gift cards in vault yet.", style: TextStyle(color: AppTheme.whiteTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _vault.length,
                  itemBuilder: (context, index) {
                    final card = _vault[index];
                    return Dismissible(
                      key: Key(card.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withAlpha(200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() {
                          _vault.removeAt(index);
                        });
                        await _saveVault();
                        messenger.showSnackBar(const SnackBar(content: Text('Gift card removed')));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              card.provider.toLowerCase().contains('amazon') ? Icons.shopping_cart_rounded : Icons.card_giftcard_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          title: Text(card.provider, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Code: ${card.claimCode}", style: const TextStyle(color: AppTheme.whiteSecondary, fontFamily: 'monospace', fontSize: 12)),
                              const SizedBox(height: 2),
                              Text("Expires: ${card.expiryDate.day}/${card.expiryDate.month}/${card.expiryDate.year}", style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 11)),
                            ],
                          ),
                          trailing: Text(
                            "₹${card.balance.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.success),
                          ),
                        ),
                      ),
                    );
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
