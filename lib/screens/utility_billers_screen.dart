import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class UtilityBillersScreen extends StatefulWidget {
  const UtilityBillersScreen({super.key});

  @override
  State<UtilityBillersScreen> createState() => _UtilityBillersScreenState();
}

class _UtilityBillersScreenState extends State<UtilityBillersScreen> {
  List<UtilityBiller> _billers = [];
  List<Bill> _allBills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savedBillers = await LocalStorageService.loadUtilityBillers();
    final savedBills = await LocalStorageService.loadBills();
    
    setState(() {
      _billers = savedBillers.map((e) => UtilityBiller(
        id: e['id'] ?? '',
        name: e['name'] ?? '',
        type: e['type'] ?? '',
        accountNumber: e['accountNumber'] ?? '',
      )).toList();

      _allBills = savedBills.map((e) => Bill(
        id: e['id'] ?? '',
        amount: double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0,
        isPaid: e['isPaid'] == true,
        dueDate: DateTime.tryParse(e['dueDate'] ?? '') ?? DateTime.now(),
        cardId: e['cardId'],
        billerId: e['billerId'],
        billerName: e['billerName'],
      )).toList();
      
      _loading = false;
    });
  }

  Future<void> _saveBillers() async {
    final list = _billers.map((e) => {
      'id': e.id,
      'name': e.name,
      'type': e.type,
      'accountNumber': e.accountNumber,
    }).toList();
    await LocalStorageService.saveUtilityBillers(list);
  }

  void _addBiller() {
    String name = '';
    String type = 'Electricity';
    String account = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Utility Biller', style: TextStyle(color: AppTheme.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: 'Biller Name (e.g. BESCOM)'),
              onChanged: (v) => name = v,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              dropdownColor: AppTheme.surfaceElevated,
              items: ['Electricity', 'Water', 'Gas', 'Internet', 'Mobile'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppTheme.white)))).toList(),
              onChanged: (v) => type = v ?? type,
              decoration: const InputDecoration(labelText: 'Service Type'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Account Number / ID'),
              onChanged: (v) => account = v,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (name.isNotEmpty && account.isNotEmpty) {
                    setState(() {
                      _billers.add(UtilityBiller(
                        id: 'UB-${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        type: type,
                        accountNumber: account,
                      ));
                    });
                    _saveBillers();
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('SAVE BILLER'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Utility Billers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _billers.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _billers.length,
                  itemBuilder: (context, index) {
                    final biller = _billers[index];
                    final bills = _allBills.where((b) => b.billerId == biller.id).toList();
                    bills.sort((a, b) => b.dueDate.compareTo(a.dueDate)); // Latest first

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withAlpha(20),
                          child: Icon(_getIconForType(biller.type), color: AppTheme.primaryBlue, size: 20),
                        ),
                        title: Text(biller.name, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("${biller.type} • ${biller.accountNumber}", style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 12)),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          if (bills.isEmpty)
                            const Text("No bill history found.", style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 12))
                          else
                            ...bills.map((bill) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Due: ${bill.dueDate.day}/${bill.dueDate.month}/${bill.dueDate.year}", style: const TextStyle(color: AppTheme.whiteSecondary, fontSize: 13)),
                                      Text(bill.isPaid ? 'PAID' : 'PENDING', style: TextStyle(color: bill.isPaid ? AppTheme.success : AppTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Text("₹${bill.amount.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBiller,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: AppTheme.surfaceElevated),
          const SizedBox(height: 24),
          const Text('No billers added yet', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Add your electricity, water, or broadband billers', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 13)),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _addBiller, child: const Text('ADD FIRST BILLER')),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'electricity': return Icons.bolt_rounded;
      case 'water': return Icons.water_drop_rounded;
      case 'gas': return Icons.local_fire_department_rounded;
      case 'internet': return Icons.wifi_rounded;
      case 'mobile': return Icons.phone_android_rounded;
      default: return Icons.receipt_rounded;
    }
  }
}
