import 'package:flutter/material.dart';
import 'screens/smart_card_screen.dart';
import 'screens/gift_card_vault_screen.dart';
import 'screens/transaction_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'models/models.dart';
import 'theme/app_theme.dart';
import 'services/local_storage_service.dart';

void main() {
  runApp(const FintechApp());
}

class FintechApp extends StatelessWidget {
  const FintechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fintech Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardHost(),
    );
  }
}

enum BillFilter { all, upcoming, paid }

class DashboardHost extends StatefulWidget {
  const DashboardHost({super.key});

  @override
  State<DashboardHost> createState() => _DashboardHostState();
}

class _DashboardHostState extends State<DashboardHost> {
  BillFilter _currentFilter = BillFilter.all;
  bool _loading = true;

  List<Bill> _bills = [];

  static final List<Bill> _defaultBills = [
    Bill(id: "B-1001", amount: 1540.50, isPaid: false, dueDate: DateTime.now().add(const Duration(days: 2))),
    Bill(id: "B-1002", amount: 499.00, isPaid: false, dueDate: DateTime.now().add(const Duration(days: 5))),
    Bill(id: "B-1003", amount: 8900.00, isPaid: true, dueDate: DateTime.now().subtract(const Duration(days: 1))),
    Bill(id: "B-1004", amount: 120.00, isPaid: false, dueDate: DateTime.now().add(const Duration(days: 12))),
  ];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    final saved = await LocalStorageService.loadBills();
    setState(() {
      if (saved.isNotEmpty) {
        _bills = saved.map((m) => Bill(
          id: m['id'] as String,
          amount: (m['amount'] as num).toDouble(),
          isPaid: m['isPaid'] as bool,
          dueDate: DateTime.parse(m['dueDate'] as String),
        )).toList();
      } else {
        _bills = List.from(_defaultBills);
      }
      _loading = false;
    });
  }

  Future<void> _saveBills() async {
    await LocalStorageService.saveBills(
      _bills.map((b) => {
        'id': b.id,
        'amount': b.amount,
        'isPaid': b.isPaid,
        'dueDate': b.dueDate.toIso8601String(),
      }).toList(),
    );
  }

  int get _unpaidCount => _bills.where((b) => !b.isPaid).length;

  @override
  Widget build(BuildContext context) {
    final filteredBills = _bills.where((bill) {
      if (_currentFilter == BillFilter.upcoming) return !bill.isPaid;
      if (_currentFilter == BillFilter.paid) return bill.isPaid;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fintech Vault'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Column(
              children: [
                // ── Summary banner ─────────────────────────────
                _buildSummaryBanner(),

                // ── Filter chips ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: SegmentedButton<BillFilter>(
                    segments: [
                      ButtonSegment(
                        value: BillFilter.all,
                        label: const Text('All'),
                        icon: const Icon(Icons.list_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: BillFilter.upcoming,
                        label: const Text('Upcoming'),
                        icon: const Icon(Icons.pending_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: BillFilter.paid,
                        label: const Text('Paid'),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      ),
                    ],
                    selected: {_currentFilter},
                    onSelectionChanged: (s) => setState(() => _currentFilter = s.first),
                  ),
                ),

                // ── Bills list ─────────────────────────────────
                Expanded(
                  child: filteredBills.isEmpty
                      ? _emptyBills()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          itemCount: filteredBills.length,
                          itemBuilder: (context, index) {
                            final bill = filteredBills[index];
                            return _buildBillCard(bill);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBanner() {
    final totalDue = _bills.where((b) => !b.isPaid).fold(0.0, (s, b) => s + b.amount);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1600), Color(0xFF2A2200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.gold, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Outstanding', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 12, letterSpacing: 0.5)),
              Text(
                '₹${totalDue.toStringAsFixed(2)}',
                style: const TextStyle(color: AppTheme.gold, fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('PENDING', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 10, letterSpacing: 1)),
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppTheme.danger, size: 16),
                  const SizedBox(width: 4),
                  Text('$_unpaidCount bills', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(Bill bill) {
    final daysLeft = bill.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0 && !bill.isPaid;
    final urgentColor = isOverdue ? AppTheme.danger : daysLeft <= 2 ? Colors.orange : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: bill.isPaid ? AppTheme.divider : urgentColor.withAlpha(80),
          width: bill.isPaid ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (bill.isPaid ? AppTheme.success : urgentColor).withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                bill.isPaid ? Icons.check_circle_rounded : (isOverdue ? Icons.warning_rounded : Icons.receipt_rounded),
                color: bill.isPaid ? AppTheme.success : urgentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.id, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.whiteTertiary),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue ? 'Overdue by ${-daysLeft}d' : bill.isPaid ? 'Paid' : 'Due in ${daysLeft}d',
                        style: TextStyle(
                          color: bill.isPaid ? AppTheme.success : urgentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${bill.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: bill.isPaid ? AppTheme.whiteSecondary : AppTheme.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (!bill.isPaid)
                  GestureDetector(
                    onTap: () {
                      setState(() => bill.isPaid = true);
                      _saveBills();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ ${bill.id} marked as paid')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('PAY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      setState(() => bill.isPaid = false);
                      _saveBills();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('↩ ${bill.id} marked as unpaid')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.undo_rounded, color: AppTheme.whiteSecondary, size: 14),
                          SizedBox(width: 4),
                          Text('Undo', style: TextStyle(color: AppTheme.whiteSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text('Fintech Vault', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w800, fontSize: 20)),
                  const Text('Your secure financial hub', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Menu items
            _drawerItem(
              context,
              icon: Icons.credit_card_rounded,
              label: 'Smart Cards',
              subtitle: 'View & manage your cards',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartCardScreen()));
              },
            ),
            _drawerItem(
              context,
              icon: Icons.card_giftcard_rounded,
              label: 'Gift Card Vault',
              subtitle: 'Store gift card codes securely',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GiftCardVaultScreen()));
              },
            ),
            _drawerItem(
              context,
              icon: Icons.receipt_long_rounded,
              label: 'Transactions',
              subtitle: 'Extended notes & receipts',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsListScreen()));
              },
            ),
            _drawerItem(
              context,
              icon: Icons.sms_rounded,
              label: 'Process SMS',
              subtitle: 'Parse bank SMS messages',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📱 SMS Background Sync Started...')),
                );
              },
            ),

            const Spacer(),
            const Divider(color: AppTheme.divider),
            _drawerItem(
              context,
              icon: Icons.settings_rounded,
              label: 'Settings',
              subtitle: 'Backup, security & more',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.gold.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.gold, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 11)),
      onTap: onTap,
    );
  }

  Widget _emptyBills() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_rounded, color: AppTheme.whiteTertiary, size: 72),
          const SizedBox(height: 16),
          const Text('No bills here', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Switch filter to see ${_currentFilter == BillFilter.paid ? "upcoming" : "paid"} bills',
              style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}
