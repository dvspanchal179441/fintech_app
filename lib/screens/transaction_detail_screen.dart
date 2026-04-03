import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  List<ExtendedTransaction> _transactionsList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final saved = await LocalStorageService.loadTransactions();
    setState(() {
      _transactionsList = saved.map((e) => ExtendedTransaction(
        transactionId: e['transactionId'] ?? '',
        note: e['note'],
        attachmentPath: e['attachmentPath'],
        cardId: e['cardId'],
        amount: double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0,
      )).toList();
      _loading = false;
    });
  }

  Future<void> _saveList() async {
    final list = _transactionsList.map((e) => {
      'transactionId': e.transactionId,
      'note': e.note,
      'attachmentPath': e.attachmentPath,
      'cardId': e.cardId,
      'amount': e.amount,
    }).toList();
    await LocalStorageService.saveTransactions(list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final newTxnTemplate = ExtendedTransaction(
                transactionId: "TXN-${DateTime.now().millisecondsSinceEpoch}",
                amount: 0.0,
              );
              
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(transaction: newTxnTemplate, isNew: true),
                ),
              );

              if (result != null && result is ExtendedTransaction) {
                setState(() {
                  _transactionsList.insert(0, result);
                });
                await _saveList();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _transactionsList.isEmpty
              ? const Center(child: Text("No transactions available.", style: TextStyle(color: AppTheme.whiteTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _transactionsList.length,
                  itemBuilder: (context, index) {
                    final txn = _transactionsList[index];
                    return Dismissible(
                      key: Key(txn.transactionId),
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
                          _transactionsList.removeAt(index);
                        });
                        await _saveList();
                        messenger.showSnackBar(const SnackBar(content: Text('Transaction deleted')));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.surfaceElevated,
                            child: Icon(Icons.receipt_long_rounded, color: AppTheme.primaryBlue, size: 20),
                          ),
                          title: Text(
                            txn.amount != null ? "₹${txn.amount!.toStringAsFixed(2)}" : "₹0.00",
                            style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            txn.note ?? "No notes",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.whiteSecondary, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.whiteTertiary),
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(transaction: txn, isNew: false),
                              ),
                            );
                            if (result != null && result is ExtendedTransaction) {
                              setState(() {
                                _transactionsList[index] = result;
                              });
                              await _saveList();
                              if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Transaction updated!')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class TransactionDetailScreen extends StatefulWidget {
  final ExtendedTransaction transaction;
  final bool isNew;

  const TransactionDetailScreen({super.key, required this.transaction, this.isNew = false});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _noteController;
  late TextEditingController _amountController;
  List<Map<String, String>> _availableCards = [];
  String? _selectedCardId;
  bool _loadingCards = true;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.transaction.note);
    _amountController = TextEditingController(text: widget.transaction.amount?.toString() ?? '');
    _selectedCardId = widget.transaction.cardId;
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await LocalStorageService.loadCards();
    setState(() {
      _availableCards = cards;
      _loadingCards = false;
      // If no card was selected but cards exist, default to first card for new transactions
      if (_selectedCardId == null && _availableCards.isNotEmpty && widget.isNew) {
        _selectedCardId = _availableCards.first['cardNumber'];
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Transaction' : 'Transaction Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Section
            const Text("AMOUNT", style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 36, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                prefixText: "₹ ",
                prefixStyle: TextStyle(color: AppTheme.primaryBlue, fontSize: 36, fontWeight: FontWeight.w800),
                border: InputBorder.none,
                hintText: "0.00",
                hintStyle: TextStyle(color: AppTheme.surfaceElevated, fontSize: 36, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 24),

            // Account/Card Selection
            const Text("SELECT ACCOUNT/CARD", style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(height: 12),
            if (_loadingCards)
              const CircularProgressIndicator(color: AppTheme.primaryBlue)
            else if (_availableCards.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.whiteTertiary),
                    SizedBox(width: 12),
                    Expanded(child: Text("No smart cards added. Please add a card first to link this transaction.", style: TextStyle(color: AppTheme.whiteSecondary, fontSize: 13))),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCardId,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceElevated,
                    hint: const Text("Select Card", style: TextStyle(color: AppTheme.whiteTertiary)),
                    items: _availableCards.map((card) {
                      final number = card['cardNumber'] ?? '';
                      final last4 = number.length >= 4 ? number.substring(number.length - 4) : '****';
                      final bank = card['bankName'] ?? 'Bank';
                      return DropdownMenuItem(
                        value: number,
                        child: Text("$bank ending in $last4", style: const TextStyle(color: AppTheme.white, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCardId = val);
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: 32),

            // Notes Section
            const Text("NOTES & TAGS", style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: "What was this for?",
                hintStyle: const TextStyle(color: AppTheme.whiteTertiary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.divider)),
              ),
            ),
            const SizedBox(height: 32),

            // Receipt Section
            const Text("RECEIPT PHOTO", style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Camera integration coming soon...")));
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
                ),
                child: widget.transaction.attachmentPath != null 
                  ? const Center(child: Icon(Icons.image, size: 40, color: AppTheme.primaryBlue))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 32, color: AppTheme.whiteTertiary),
                        SizedBox(height: 8),
                        Text("Tap to capture receipt", style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 12))
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () {
          widget.transaction.note = _noteController.text;
          widget.transaction.amount = double.tryParse(_amountController.text) ?? 0.0;
          widget.transaction.cardId = _selectedCardId;
          Navigator.pop(context, widget.transaction);
        },
        label: Text(widget.isNew ? 'CREATE' : 'SAVE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: Icon(widget.isNew ? Icons.add_rounded : Icons.check_rounded, color: Colors.white),
      ),
    );
  }
}
