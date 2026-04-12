import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/models.dart';
import '../services/sms_parser_service.dart';
import '../services/permission_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class SyncedMessagesScreen extends StatefulWidget {
  final VoidCallback onSyncComplete;

  const SyncedMessagesScreen({super.key, required this.onSyncComplete});

  @override
  State<SyncedMessagesScreen> createState() => _SyncedMessagesScreenState();
}

class _SyncedMessagesScreenState extends State<SyncedMessagesScreen> {
  bool _loading = true;
  List<SmsMessage> _messages = [];
  List<Bill> _detectedBills = [];
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final hasPerm = await PermissionService.hasSmsPermission();
    if (!hasPerm) {
      setState(() {
        _loading = false;
        _permissionDenied = true;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final messages = await SMSParserService.getAllRawMessages();
      final detected = SMSParserService.parseBillsFromMessages(messages);

      setState(() {
        _messages = messages;
        _detectedBills = detected;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed to fetch SMS: $e')));
    }
  }

  Future<void> _syncAndSaveBills() async {
    if (_detectedBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📭 No new banking bills found in SMS.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final savedBillsMapList = await LocalStorageService.loadBills();
      final existingIds = savedBillsMapList.map((b) => b['id'] as String).toSet();

      final newBills = _detectedBills.where((b) => !existingIds.contains(b.id)).toList();

      if (newBills.isEmpty) {
        setState(() => _loading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ All bills are already tracked!')),
        );
        return;
      }

      // Add to local storage manually to avoid losing other fields
      final newBillsMap = newBills.map((b) => {
        'id': b.id,
        'amount': b.amount,
        'isPaid': b.isPaid,
        'dueDate': b.dueDate.toIso8601String(),
        'cardId': b.cardId,
        'billerId': b.billerId,
        'billerName': b.billerName,
      }).toList();

      savedBillsMapList.insertAll(0, newBillsMap);
      await LocalStorageService.saveBills(savedBillsMapList);

      setState(() => _loading = false);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Added ${newBills.length} new bill(s) to tracker!')),
      );

      widget.onSyncComplete();
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inbox Sync View'),
        actions: [
          if (!_loading && !_permissionDenied && _detectedBills.isNotEmpty)
            TextButton.icon(
              onPressed: _syncAndSaveBills,
              icon: const Icon(Icons.download_rounded, color: AppTheme.primaryBlue),
              label: const Text('Import Bills', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _permissionDenied
              ? _buildPermissionDeniedState()
              : _messages.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: AppTheme.surfaceElevated,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          child: Text(
                            'Scanned ${_messages.length} messages.\nFound ${_detectedBills.length} bill(s) to sync.',
                            style: const TextStyle(color: AppTheme.whiteSecondary, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final relatedBill = _detectedBills.where((b) => b.id.contains(msg.date?.millisecondsSinceEpoch.toString() ?? 'xyz')).firstOrNull;
                              final isMatched = relatedBill != null;

                              return Card(
                                color: isMatched ? AppTheme.surfaceElevated : AppTheme.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isMatched ? AppTheme.primaryBlue : AppTheme.divider,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          msg.address ?? 'Unknown Sender',
                                          style: TextStyle(
                                            color: isMatched ? AppTheme.primaryBlue : AppTheme.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (msg.date != null)
                                        Text(
                                          '${msg.date!.day}/${msg.date!.month}/${msg.date!.year}',
                                          style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        msg.body ?? '',
                                        style: const TextStyle(color: AppTheme.whiteSecondary, fontSize: 13),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isMatched) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue.withAlpha(30),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryBlue, size: 14),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Detected Due: ₹${relatedBill.amount.toStringAsFixed(0)}',
                                                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_rounded, color: AppTheme.whiteTertiary, size: 72),
          const SizedBox(height: 16),
          const Text('No recent SMS found', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sms_failed_rounded, color: AppTheme.danger, size: 72),
          const SizedBox(height: 16),
          const Text('SMS Permission Required', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('We need SMS permission to sync your bills.', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await PermissionService.openSettings();
              if (mounted) Navigator.pop(context); // Force user to reopen
            },
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    );
  }
}
