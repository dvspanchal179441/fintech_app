import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';

class MembershipVaultScreen extends StatefulWidget {
  const MembershipVaultScreen({super.key});

  @override
  State<MembershipVaultScreen> createState() => _MembershipVaultScreenState();
}

class _MembershipVaultScreenState extends State<MembershipVaultScreen> {
  List<Map<String, String>> _memberships = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemberships();
  }

  Future<void> _loadMemberships() async {
    // Re-use standard Card storage for now or a specific one
    await LocalStorageService.loadCards(); // Placeholder logic
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Memberships'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addMembership(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _memberships.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _memberships.length,
                  itemBuilder: (context, index) => _buildMembershipCard(_memberships[index]),
                ),
    );
  }

  Widget _buildMembershipCard(Map<String, String> membership) {
     return Container(
       margin: const EdgeInsets.only(bottom: 16),
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: AppTheme.surfaceElevated,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: AppTheme.divider),
       ),
       child: Row(
         children: [
           const Icon(Icons.stars_rounded, color: Colors.amber, size: 32),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(membership['name'] ?? 'Gold Member', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                 const Text('Valid until Dec 2026', style: TextStyle(color: AppTheme.whiteSecondary, fontSize: 12)),
               ],
             ),
           ),
           const Text('ACTIVE', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 10)),
         ],
       ),
     );
  }

  void _addMembership() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membership capture not implemented yet.')));
  }

  Widget _emptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars_rounded, color: AppTheme.whiteTertiary, size: 72),
          const SizedBox(height: 16),
          const Text('No memberships added', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const Text('Store your loyalty cards here', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}
