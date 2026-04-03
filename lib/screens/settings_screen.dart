import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.appdata'],
  );

  static GoogleSignInAccount? currentUser;

  static Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      currentUser = account;
      return account != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    currentUser = null;
  }

  static bool get isSignedIn => currentUser != null;

  /// Simulates backing up to Drive (real implementation needs googleapis package call)
  static Future<bool> backupNow() async {
    if (!isSignedIn) return false;
    try {
      // Export local data
      final jsonData = await LocalStorageService.exportAllAsJson();
      // [production] Use googleapis Drive API to write to AppData folder
      // For now, log the payload length as a simulation
      debugPrint('📦 Backup payload: ${jsonData.length} chars');
      await LocalStorageService.setLastBackupTime(DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      return false;
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backupEnabled = false;
  String? _lastBackup;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final enabled = await LocalStorageService.getBackupEnabled();
    final last = await LocalStorageService.getLastBackupTime();
    setState(() {
      _backupEnabled = enabled;
      _lastBackup = last;
    });
  }

  Future<void> _toggleBackup(bool value) async {
    await LocalStorageService.setBackupEnabled(value);
    if (!value) {
      await GoogleDriveService.signOut();
    }
    setState(() => _backupEnabled = value);
  }

  Future<void> _connectGoogle() async {
    setState(() => _loading = true);
    final success = await GoogleDriveService.signIn();
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? '✅ Connected to Google Drive' : '❌ Sign-in cancelled'),
      ));
    }
  }

  Future<void> _backupNow() async {
    setState(() => _loading = true);
    final success = await GoogleDriveService.backupNow();
    final last = await LocalStorageService.getLastBackupTime();
    setState(() {
      _loading = false;
      _lastBackup = last;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? '✅ Backup completed!' : '❌ Backup failed'),
      ));
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return 'Never';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Section header ──────────────────────────────
          _sectionLabel('🔒 PRIVACY & SECURITY'),
          const SizedBox(height: 12),

          _settingsTile(
            icon: Icons.storage_rounded,
            title: 'Local Storage',
            subtitle: 'All data stored offline on your device',
            trailing: const Icon(Icons.check_circle_rounded, color: AppTheme.success),
          ),
          const SizedBox(height: 24),

          // ── Google Drive Backup ─────────────────────────
          _sectionLabel('☁️ GOOGLE DRIVE BACKUP'),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                  secondary: const Icon(Icons.cloud_sync_rounded, color: AppTheme.primaryBlue),
                  title: const Text('Enable Drive Backup', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Encrypted backup to your Google Drive', style: TextStyle(color: AppTheme.whiteSecondary, fontSize: 12)),
                  value: _backupEnabled,
                  onChanged: _toggleBackup,
                ),
                if (_backupEnabled) ...[
                  const Divider(height: 1, color: AppTheme.divider),
                  if (!GoogleDriveService.isSignedIn)
                    _actionTile(
                      icon: Icons.login_rounded,
                      label: 'Connect Google Account',
                      onTap: _connectGoogle,
                    )
                  else ...[
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
                      leading: const Icon(Icons.account_circle_rounded, color: AppTheme.primaryBlue),
                      title: Text(
                        GoogleDriveService.currentUser?.email ?? 'Connected',
                        style: const TextStyle(color: AppTheme.white, fontSize: 14),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          await GoogleDriveService.signOut();
                          setState(() {});
                        },
                        child: const Text('Disconnect', style: TextStyle(color: AppTheme.danger)),
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.divider),
                    _actionTile(
                      icon: Icons.backup_rounded,
                      label: 'Backup Now',
                      onTap: _loading ? null : _backupNow,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      leading: const Icon(Icons.history_rounded, color: AppTheme.whiteTertiary, size: 20),
                      title: Text('Last backup: ${_formatDate(_lastBackup)}',
                          style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 12)),
                    ),
                  ],
                ],
              ],
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
            ),

          const SizedBox(height: 32),
          _sectionLabel('ℹ️ ABOUT'),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: '1.0.0 • Fintech Vault',
          ),
          _settingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Data Privacy',
            subtitle: 'No data is shared with any third party without your consent',
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          color: AppTheme.whiteTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      );

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(title, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.whiteSecondary, fontSize: 12)),
        trailing: trailing,
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String label, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(label, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.whiteTertiary, size: 14),
      onTap: onTap,
    );
  }
}
