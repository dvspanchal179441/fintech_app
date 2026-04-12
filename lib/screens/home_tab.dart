import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';
import '../services/sms_parser_service.dart';
import '../services/permission_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

enum BillFilter { all, upcoming, paid }

class _HomeTabState extends State<HomeTab> {
  BillFilter _currentFilter = BillFilter.upcoming; // Unpaid/Upcoming as default
  bool _loading = true;
  List<Bill> _bills = [];

  final PageController _pageController = PageController();
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  Future<void> _loadBills() async {
    final saved = await LocalStorageService.loadBills();
    setState(() {
      _bills = saved.map((m) => Bill(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        isPaid: m['isPaid'] as bool,
        dueDate: DateTime.parse(m['dueDate'] as String),
        cardId: m['cardId'] as String?,
        billerId: m['billerId'] as String?,
        billerName: m['billerName'] as String?,
      )).toList();
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
        'cardId': b.cardId,
        'billerId': b.billerId,
        'billerName': b.billerName,
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBills = _bills.where((bill) {
      if (_currentFilter == BillFilter.upcoming) return !bill.isPaid;
      if (_currentFilter == BillFilter.paid) return bill.isPaid;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync from SMS',
            onPressed: () => _simulateSmsSync(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : Column(
              children: [
                _buildStatsCarousel(),
                _buildPageIndicator(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SegmentedButton<BillFilter>(
                    segments: const [
                      ButtonSegment(value: BillFilter.all, label: Text('All'), icon: Icon(Icons.list_rounded, size: 16)),
                      ButtonSegment(value: BillFilter.upcoming, label: Text('Unpaid'), icon: Icon(Icons.pending_rounded, size: 16)),
                      ButtonSegment(value: BillFilter.paid, label: Text('Paid'), icon: Icon(Icons.check_circle_outline_rounded, size: 16)),
                    ],
                    selected: {_currentFilter},
                    onSelectionChanged: (s) => setState(() => _currentFilter = s.first),
                  ),
                ),
                Expanded(
                  child: filteredBills.isEmpty
                      ? _emptyBills()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: filteredBills.length,
                          itemBuilder: (context, index) {
                            return _buildBillCard(filteredBills[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAdd(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildStatsCarousel() {
    return SizedBox(
      height: 160,
      child: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _activePage = page),
        children: [
          _buildOverviewCard(),
          _buildCategoryCard(),
          _buildMonthlyTrendCard(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: _activePage == index ? 18 : 6,
          decoration: BoxDecoration(
            color: _activePage == index ? AppTheme.primaryBlue : AppTheme.whiteTertiary.withAlpha(100),
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final totalDue = _bills.where((b) => !b.isPaid).fold(0.0, (s, b) => s + b.amount);
    final totalPaid = _bills.where((b) => b.isPaid).fold(0.0, (s, b) => s + b.amount);
    final allTotal = totalDue + totalPaid;
    final progress = allTotal > 0 ? (totalPaid / allTotal) : 0.0;

    return _baseStatCard(
      title: 'TOTAL PENDING',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('₹${totalDue.toStringAsFixed(0)}', 
                    style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${(progress * 100).toStringAsFixed(0)}% of total bills paid', 
                    style: const TextStyle(color: AppTheme.whiteSecondary, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: 70, height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.divider,
                  color: AppTheme.primaryBlue,
                ),
                Center(
                  child: Text('${(progress * 100).toStringAsFixed(0)}%', 
                      style: const TextStyle(color: AppTheme.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final cardPending = _bills.where((b) => !b.isPaid && b.cardId != null).fold(0.0, (s, b) => s + b.amount);
    final utilityPending = _bills.where((b) => !b.isPaid && b.billerId != null).fold(0.0, (s, b) => s + b.amount);
    
    return _baseStatCard(
      title: 'CATEGORY BREAKDOWN',
      child: Row(
        children: [
          _categorySmallCard(Icons.credit_card_rounded, 'Cards', cardPending, Colors.blue),
          const SizedBox(width: 12),
          _categorySmallCard(Icons.electrical_services_rounded, 'Utilities', utilityPending, Colors.orange),
        ],
      ),
    );
  }

  Widget _categorySmallCard(IconData icon, String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppTheme.whiteSecondary, fontSize: 11)),
            Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendCard() {
    final Map<String, double> monthlyData = {};
    final now = DateTime.now();
    for (var i = 0; i < 5; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = "${date.month}/${date.year % 100}";
        monthlyData[key] = _bills
            .where((b) => b.dueDate.month == date.month && b.dueDate.year == date.year)
            .fold(0.0, (s, b) => s + b.amount);
    }

    final keys = monthlyData.keys.toList().reversed.toList();
    final maxVal = monthlyData.values.fold(1.0, (m, v) => v > m ? v : m);

    return _baseStatCard(
      title: 'MONTHLY TRENDS',
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: keys.map((k) {
                final heightFactor = monthlyData[k]! / maxVal;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: (60 * heightFactor).clamp(4, 60).toDouble(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withAlpha(100)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(k, style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 9)),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showAllHistoryModal(),
            child: const Text('VIEW ALL HISTORY', 
                style: TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _baseStatCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _showAllHistoryModal() {
    // Generate statistical list for all months and years
    final Map<String, Map<String, double>> history = {};
    for (var bill in _bills) {
        final key = "${bill.dueDate.year}";
        final monthKey = _getMonthName(bill.dueDate.month);
        history[key] ??= {};
        history[key]![monthKey] = (history[key]![monthKey] ?? 0) + bill.amount;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('ALL-TIME STATISTICS', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: history.keys.toList().reversed.map((year) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(year, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      ...history[year]!.keys.map((month) => ListTile(
                        leading: const Icon(Icons.calendar_today_rounded, size: 20),
                        title: Text(month, style: const TextStyle(color: AppTheme.white)),
                        trailing: Text('₹${history[year]![month]!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                      )),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return names[month - 1];
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
        border: Border.all(color: bill.isPaid ? AppTheme.divider : urgentColor.withAlpha(80)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: urgentColor.withAlpha(20), borderRadius: BorderRadius.circular(14)),
          child: Icon(bill.isPaid ? Icons.check_circle_rounded : Icons.receipt_rounded, color: urgentColor),
        ),
        title: Text(bill.billerName ?? 'Bill', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
        subtitle: Text(isOverdue ? 'Overdue' : 'Due in $daysLeft days', style: TextStyle(color: urgentColor, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${bill.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w800, fontSize: 16)),
            if (!bill.isPaid)
               GestureDetector(
                 onTap: () async {
                   setState(() => bill.isPaid = true);
                   await _saveBills();
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                         content: Text('✅ Bill marked as paid!'),
                         backgroundColor: AppTheme.success,
                       ),
                     );
                   }
                 },
                 child: Text('PAY', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 12)),
               ),
          ],
        ),
      ),
    );
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Add Bill', style: TextStyle(color: AppTheme.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _quickAddOption(
              ctx,
              icon: Icons.credit_card_rounded,
              title: 'Credit Card Bill',
              subtitle: 'Add bill for an existing card',
              onTap: () => _addBillFlow(ctx, isUtility: false),
            ),
            const SizedBox(height: 12),
            _quickAddOption(
              ctx,
              icon: Icons.receipt_long_rounded,
              title: 'Utility Bill',
              subtitle: 'Electricity, Water, WiFi etc.',
              onTap: () => _addBillFlow(ctx, isUtility: true),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _quickAddOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: AppTheme.primaryBlue.withAlpha(20), child: Icon(icon, color: AppTheme.primaryBlue)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.whiteTertiary, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _addBillFlow(BuildContext context, {required bool isUtility}) async {
    Navigator.pop(context); // close bottom sheet
    final messenger = ScaffoldMessenger.of(context);
    List<dynamic> sources = [];
    if (isUtility) {
      sources = await LocalStorageService.loadUtilityBillers();
    } else {
      sources = await LocalStorageService.loadCards();
    }

    if (sources.isEmpty) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text("No ${isUtility ? 'Billers' : 'Cards'} found.")));
      }
      return;
    }

    if (!context.mounted) return;

    dynamic selectedSource;
    double amount = 0;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add ${isUtility ? 'Utility' : 'Card'} Bill', style: const TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              DropdownButtonFormField<dynamic>(
                initialValue: selectedSource,
                dropdownColor: AppTheme.surfaceElevated,
                items: sources.map((s) {
                  String label = isUtility ? s['name'] : "${s['bankName']} Card (**${(s['cardNumber'] as String).substring((s['cardNumber'] as String).length - 4)})";
                  return DropdownMenuItem(value: s, child: Text(label, style: const TextStyle(color: AppTheme.white, fontSize: 13)));
                }).toList(),
                onChanged: (v) => setModalState(() => selectedSource = v),
                decoration: InputDecoration(labelText: 'Select ${isUtility ? 'Biller' : 'Card'}'),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.white),
                decoration: const InputDecoration(labelText: 'Bill Amount', prefixText: '₹ '),
                onChanged: (v) => amount = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedSource != null && amount > 0) Navigator.pop(ctx, true);
                  },
                  child: const Text('CREATE BILL'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        setState(() {
          _bills.insert(0, Bill(
            id: "B-${DateTime.now().millisecondsSinceEpoch}",
            amount: amount,
            isPaid: false,
            dueDate: dueDate,
            billerId: isUtility ? selectedSource['id'] : null,
            billerName: isUtility ? selectedSource['name'] : selectedSource['bankName'],
            cardId: isUtility ? null : selectedSource['cardNumber'],
          ));
        });
        await _saveBills();
      }
    });
  }

  Widget _emptyBills() {
    return const Center(child: Text('No bills found', style: TextStyle(color: AppTheme.whiteTertiary)));
  }

  Future<void> _simulateSmsSync() async {
    final messenger = ScaffoldMessenger.of(context);

    // Check SMS permission first
    final hasPerm = await PermissionService.hasSmsPermission();
    if (!hasPerm) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('⚠️ SMS permission denied. Enable in Settings.'),
          action: SnackBarAction(
            label: 'SETTINGS',
            onPressed: PermissionService.openSettings,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final detectedBills = await SMSParserService.scanInboxForBills();

      if (!mounted) return;

      if (detectedBills.isEmpty) {
        setState(() => _loading = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('📭 No new banking bills found in SMS.')),
        );
        return;
      }

      // Deduplicate: skip bills already in list (same ID)
      final existingIds = _bills.map((b) => b.id).toSet();
      final newBills = detectedBills.where((b) => !existingIds.contains(b.id)).toList();

      setState(() {
        _bills.insertAll(0, newBills);
        _loading = false;
      });

      await _saveBills();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              newBills.isEmpty
                  ? '✅ SMS scanned — all bills already tracked.'
                  : '✅ Found ${newBills.length} new bill${newBills.length > 1 ? 's' : ''} from SMS!',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('❌ SMS scan failed: $e')),
      );
    }
  }
}
