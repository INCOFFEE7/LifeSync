import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/data/providers/google_auth_provider.dart';
import 'package:lifesync_app/data/services/google_drive_service.dart';
import 'package:lifesync_app/core/sync/sync_engine.dart';

class CloudBackupSettingsScreen extends ConsumerStatefulWidget {
  const CloudBackupSettingsScreen({super.key});

  @override
  ConsumerState<CloudBackupSettingsScreen> createState() => _CloudBackupSettingsScreenState();
}

class _CloudBackupSettingsScreenState extends ConsumerState<CloudBackupSettingsScreen> {
  bool _isSyncing = false;
  bool _isConnecting = false;
  String? _lastError;
  String? _spreadsheetId;

  @override
  void initState() {
    super.initState();
    _loadSpreadsheetId();
  }

  Future<void> _loadSpreadsheetId() async {
    final authService = ref.read(googleAuthServiceProvider);
    final id = await authService.getSpreadsheetId();
    if (mounted) setState(() => _spreadsheetId = id);
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(googleAuthServiceProvider);
    final user = authService.currentUser;
    final isConnected = user != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Backup & Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Status Card
          Card(
            color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: isConnected ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'Terhubung' : 'Belum Terhubung',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                        if (isConnected) Text(user.email, style: const TextStyle(fontSize: 12)),
                        if (_spreadsheetId != null && isConnected)
                          Text('Spreadsheet: ...${_spreadsheetId!.substring(_spreadsheetId!.length > 8 ? _spreadsheetId!.length - 8 : 0)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Error message if any
          if (_lastError != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_lastError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _lastError = null),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Text('Google Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isConnected ? Colors.blue.shade100 : Colors.grey.shade200,
              child: Icon(
                isConnected ? Icons.person : Icons.person_outline,
                color: isConnected ? Colors.blue : Colors.grey,
              ),
            ),
            title: Text(isConnected ? user.displayName ?? user.email : 'Belum Login Google'),
            subtitle: Text(isConnected ? user.email : 'Tap tombol untuk connect ke Google Drive'),
            trailing: _isConnecting
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : ElevatedButton.icon(
                  onPressed: _handleConnectDisconnect,
                  icon: Icon(isConnected ? Icons.logout : Icons.login, size: 16),
                  label: Text(isConnected ? 'Disconnect' : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? Colors.red.shade400 : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
          ),
          const Divider(),
          const Text('Sinkronisasi', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            enabled: isConnected && !_isSyncing,
            leading: const Icon(Icons.sync),
            title: const Text('Sync Sekarang'),
            subtitle: const Text('Upload data lokal ke Google Sheets'),
            trailing: _isSyncing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: isConnected && !_isSyncing ? _performSync : null,
          ),
          ListTile(
            enabled: isConnected && !_isSyncing,
            leading: const Icon(Icons.download),
            title: const Text('Restore Data'),
            subtitle: const Text('Tarik semua data dari Google Sheets ke perangkat ini'),
            trailing: const Icon(Icons.chevron_right),
            onTap: isConnected && !_isSyncing ? _performRestore : null,
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnectDisconnect() async {
    setState(() { _isConnecting = true; _lastError = null; });
    final authService = ref.read(googleAuthServiceProvider);
    final isConnected = authService.currentUser != null;

    try {
      if (isConnected) {
        await authService.signOut();
        if (mounted) setState(() => _spreadsheetId = null);
      } else {
        final account = await authService.signIn();
        if (account == null) {
          if (mounted) setState(() => _lastError = 'Login dibatalkan atau gagal. Pastikan akun Google terdaftar di aplikasi ini.');
          return;
        }

        final client = await authService.getAuthenticatedClient();
        if (client == null) {
          if (mounted) setState(() => _lastError = 'Gagal mendapatkan akses OAuth. Coba login ulang.');
          return;
        }

        final driveService = ref.read(googleDriveServiceProvider);
        final folderId = await driveService.getOrCreateBackupFolder(client);
        if (folderId == null) {
          if (mounted) setState(() => _lastError = 'Gagal membuat folder backup di Google Drive.');
          return;
        }

        final spreadsheetId = await driveService.getOrCreateSpreadsheet(client, folderId);
        if (spreadsheetId == null) {
          if (mounted) setState(() => _lastError = 'Gagal membuat spreadsheet.');
          return;
        }

        await authService.saveSpreadsheetId(spreadsheetId);
        if (mounted) setState(() => _spreadsheetId = spreadsheetId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Berhasil terhubung ke Google Drive!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _lastError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }
  
  Future<void> _performSync() async {
    setState(() { _isSyncing = true; _lastError = null; });
    try {
      final syncEngine = ref.read(syncEngineProvider);
      await syncEngine.performSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sync berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _lastError = 'Sync gagal: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _performRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text('Data lokal yang berbeda dari cloud akan ditimpa. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _isSyncing = true; _lastError = null; });
    try {
      final syncEngine = ref.read(syncEngineProvider);
      await syncEngine.performSync(); // Full sync acts as restore
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Restore berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _lastError = 'Restore gagal: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
