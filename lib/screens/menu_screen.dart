import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_grid_tile.dart';
import 'smart_card_screen.dart';
import 'gift_card_vault_screen.dart';
import 'transaction_detail_screen.dart';
import 'utility_billers_screen.dart';
import 'settings_screen.dart';
import 'membership_vault_screen.dart';
import 'tasks_screen.dart';
import 'notes_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: false,
        backgroundColor: AppTheme.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Services', style: TextStyle(color: AppTheme.whiteSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                MenuGridTile(
                  icon: Icons.credit_card_rounded,
                  label: 'Payment Cards',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartCardScreen())),
                ),
                MenuGridTile(
                  icon: Icons.card_membership_rounded,
                  label: 'Memberships',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipVaultScreen())),
                ),
                MenuGridTile(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Gift Cards',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiftCardVaultScreen())),
                ),
                MenuGridTile(
                  icon: Icons.task_alt_rounded,
                  label: 'Tasks',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())),
                ),
                MenuGridTile(
                  icon: Icons.sticky_note_2_rounded,
                  label: 'Notes',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())),
                ),
                MenuGridTile(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsListScreen())),
                ),
                MenuGridTile(
                  icon: Icons.electrical_services_rounded,
                  label: 'Utility',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilityBillersScreen())),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('Security & Backup', style: TextStyle(color: AppTheme.whiteSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.security_rounded),
              title: const Text('Security Center'),
              subtitle: const Text('Local storage, privacy stats', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 11)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync_rounded),
              title: const Text('Cloud Backup'),
              subtitle: const Text('Sync with Google Drive', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 11)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('General Settings'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
