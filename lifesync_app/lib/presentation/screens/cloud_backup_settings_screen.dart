import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/data/providers/google_auth_provider.dart';
import 'package:lifesync_app/data/services/google_drive_service.dart';
import 'package:lifesync_app/core/sync/sync_engine.dart';
import 'package:lifesync_app/core/services/csv_export_service.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

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
      backgroundColor: LsColors.paper(context),
      appBar: AppBar(
        title: const Text('Cloud Backup & Sync'),
        backgroundColor: LsColors.paper(context),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Status Banner ──
          LsCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isConnected ? LsColors.income : LsColors.amber).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: isConnected ? LsColors.income : LsColors.amber,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isConnected ? 'Terhubung' : 'Belum Terhubung',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isConnected ? LsColors.income : LsColors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          LsChip(isConnected ? 'Aktif' : 'Offline', color: isConnected ? LsColors.income : LsColors.mute(context)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isConnected ? user.email : 'Hubungkan akun Google Drive untuk sync data',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: LsColors.mute(context)),
                      ),
                      if (_spreadsheetId != null && isConnected) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Spreadsheet: ...${_spreadsheetId!.substring(_spreadsheetId!.length > 8 ? _spreadsheetId!.length - 8 : 0)}',
                          style: TextStyle(fontSize: 11, color: LsColors.mute(context)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Error Alert ──
          if (_lastError != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LsColors.expense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LsColors.expense.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: LsColors.expense, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_lastError!, style: const TextStyle(color: LsColors.expense, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: LsColors.expense),
                    onPressed: () => setState(() => _lastError = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Google Account Section ──
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 8),
            child: LsEyebrow('Akun Google'),
          ),
          LsCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isConnected ? LsColors.brand.withValues(alpha: 0.12) : LsColors.line(context),
                  child: Icon(
                    isConnected ? Icons.person_rounded : Icons.person_outline_rounded,
                    color: isConnected ? LsColors.brand : LsColors.mute(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? (user.displayName ?? user.email) : 'Belum Login Google',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: LsColors.ink(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isConnected ? user.email : 'Ketuk tombol untuk menghubungkan akun',
                        style: TextStyle(fontSize: 11.5, color: LsColors.mute(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _isConnecting
                    ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton.icon(
                        onPressed: _handleConnectDisconnect,
                        icon: Icon(isConnected ? Icons.logout_rounded : Icons.login_rounded, size: 16),
                        label: Text(isConnected ? 'Disconnect' : 'Connect', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        style: FilledButton.styleFrom(
                          backgroundColor: isConnected ? LsColors.expense : LsColors.brand,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Cloud Sync Section ──
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 8),
            child: LsEyebrow('Sinkronisasi Cloud'),
          ),
          LsCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  enabled: isConnected && !_isSyncing,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: LsColors.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.sync_rounded, color: LsColors.brand, size: 20),
                  ),
                  title: const Text('Sync Sekarang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Kirim data lokal terbaru dan perbarui Google Sheets', style: TextStyle(fontSize: 12)),
                  trailing: _isSyncing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: isConnected && !_isSyncing ? _performSync : null,
                ),
                Divider(height: 1, indent: 56, color: LsColors.line(context)),
                ListTile(
                  enabled: isConnected && !_isSyncing,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: LsColors.violet.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.cloud_download_rounded, color: LsColors.violet, size: 20),
                  ),
                  title: const Text('Restore Data', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Tarik dan perbarui semua data dari Google Sheets', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: isConnected && !_isSyncing ? _performRestore : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Local Backup / CSV Export Section ──
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 8),
            child: LsEyebrow('Cadangan Lokal (Offline)'),
          ),
          LsCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: LsColors.income.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.file_download_rounded, color: LsColors.income, size: 20),
              ),
              title: const Text('Ekspor Data CSV', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Simpan file CSV ke folder Download atau salin ke clipboard', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => CsvExportService.showExportDialog(context, ref),
            ),
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
          if (mounted) setState(() => _lastError = 'Login dibatalkan atau gagal.');
          return;
        }

        final client = await authService.getAuthenticatedClient();
        if (client == null) {
          if (mounted) setState(() => _lastError = 'Gagal mendapatkan akses OAuth.');
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
              backgroundColor: LsColors.income,
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
            content: Text('✅ Sync berhasil! Data diperbarui di Google Sheets.'),
            backgroundColor: LsColors.income,
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
    final confirmed = await showLsConfirmDialog(
      context: context,
      title: 'Restore Data?',
      message: 'Data lokal yang berbeda dari Google Sheets akan disinkronkan dan diperbarui. Lanjutkan?',
      confirmLabel: 'Ya, Restore',
      cancelLabel: 'Batal',
      isDanger: false,
    );
    if (confirmed != true) return;

    setState(() { _isSyncing = true; _lastError = null; });
    try {
      final syncEngine = ref.read(syncEngineProvider);
      await syncEngine.performSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Restore berhasil! Data telah disinkronkan.'),
            backgroundColor: LsColors.income,
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
