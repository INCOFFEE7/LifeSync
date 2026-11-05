import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lifesync_app/core/providers/core_providers.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';
import 'package:isar/isar.dart';
import 'package:lifesync_app/domain/entities/financial_note.dart';
import 'package:lifesync_app/domain/entities/financial_item.dart';
import 'package:lifesync_app/domain/entities/bill.dart';
import 'package:lifesync_app/domain/entities/shopping_item.dart';
import 'package:lifesync_app/domain/entities/reminder.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';

class CsvExportService {
  static Future<String> generateCsv(Isar db) async {
    final buffer = StringBuffer();

    // 1. Catatan & Transaksi Keuangan
    buffer.writeln('# CATATAN DAN TRANSAKSI KEUANGAN');
    buffer.writeln('ID Catatan,Tanggal,Judul Catatan,Deskripsi Item,Tipe,Nominal,Catatan Tambahan');
    final notes = await db.financialNotes.where().findAll();
    final items = await db.financialItems.where().findAll();
    final itemsByNote = <int, List<FinancialItem>>{};
    for (final item in items) {
      itemsByNote.putIfAbsent(item.noteId, () => []).add(item);
    }
    for (final n in notes) {
      final noteItems = itemsByNote[n.id] ?? [];
      final dateStr = DateFormat('yyyy-MM-dd').format(n.date);
      if (noteItems.isEmpty) {
        buffer.writeln('${n.id},$dateStr,"${_escape(n.title)}",-,-,0,"${_escape(n.notes ?? '')}"');
      } else {
        for (final item in noteItems) {
          buffer.writeln('${n.id},$dateStr,"${_escape(n.title)}","${_escape(item.description)}",${item.type},${item.amount.toInt()},"${_escape(n.notes ?? '')}"');
        }
      }
    }
    buffer.writeln();

    // 2. Tagihan & Piutang
    buffer.writeln('# DAFTAR TAGIHAN DAN PIUTANG');
    buffer.writeln('ID,Tipe,Nama,Rencana Nominal,Realisasi Nominal,Status,Jatuh Tempo,Dibayar Oleh,Diterima Oleh,Catatan');
    final bills = await db.bills.where().findAll();
    for (final b in bills) {
      final dueStr = DateFormat('yyyy-MM-dd HH:mm').format(b.dueDate);
      final isPaidStr = b.isPaid ? 'Lunas' : 'Belum Lunas';
      buffer.writeln('${b.id},${b.billType},"${_escape(b.name)}",${b.amount.toInt()},${(b.realizationAmount ?? 0).toInt()},$isPaidStr,$dueStr,"${_escape(b.paidBy ?? '')}","${_escape(b.receivedBy ?? '')}","${_escape(b.notes ?? '')}"');
    }
    buffer.writeln();

    // 3. Daftar Belanja
    buffer.writeln('# DAFTAR BELANJA');
    buffer.writeln('ID,Nama Barang,Kategori,Status,Harga Estimasi,Harga Realisasi,Lokasi Toko,Dibeli Oleh,Catatan');
    final shopping = await db.shoppingItems.where().findAll();
    for (final s in shopping) {
      final statusStr = s.isChecked ? 'Sudah Dibeli' : 'Belum Dibeli';
      buffer.writeln('${s.id},"${_escape(s.name)}","${_escape(s.category ?? 'Lainnya')}",$statusStr,${s.price.toInt()},${(s.realizationPrice ?? 0).toInt()},"${_escape(s.location ?? '')}","${_escape(s.purchasedBy ?? '')}","${_escape(s.notes ?? '')}"');
    }
    buffer.writeln();

    // 4. Target Tabungan
    buffer.writeln('# TARGET NABUNG');
    buffer.writeln('ID,Nama Target,Target Nominal,Mode,Harian Tetap,Tanggal Mulai,Tanggal Selesai,Status');
    final targets = await db.incomeTargets.where().findAll();
    for (final t in targets) {
      final startStr = DateFormat('yyyy-MM-dd').format(t.startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(t.endDate);
      buffer.writeln('${t.id},"${_escape(t.name)}",${t.targetAmount.toInt()},${t.mode},${t.fixedDailyAmount.toInt()},$startStr,$endStr,${t.status.name}');
    }
    buffer.writeln();

    // 5. Agenda & Pengingat
    buffer.writeln('# AGENDA DAN PENGINGAT');
    buffer.writeln('ID,Judul,Kategori,Prioritas,Waktu Mulai,Waktu Selesai,Status,Selesai Pada,Deskripsi');
    final reminders = await db.reminders.where().findAll();
    for (final r in reminders) {
      final startStr = DateFormat('yyyy-MM-dd HH:mm').format(r.targetDateTime);
      final endStr = DateFormat('yyyy-MM-dd HH:mm').format(r.effectiveEndTime);
      final completedStr = r.completedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(r.completedAt!) : '-';
      buffer.writeln('${r.id},"${_escape(r.title)}",${r.category.name},${r.priority.name},$startStr,$endStr,${r.status.name},$completedStr,"${_escape(r.description ?? '')}"');
    }

    return buffer.toString();
  }

  static String _escape(String value) {
    return value.replaceAll('"', '""').replaceAll('\n', ' ');
  }

  static Future<String> saveCsvToFile(String csvContent) async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        try {
          dir = await getExternalStorageDirectory();
        } catch (_) {}
      }
    }
    dir ??= await getApplicationDocumentsDirectory();

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'LifeSync_Export_$dateStr.csv';
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(csvContent, encoding: utf8);
    return file.path;
  }

  static Future<void> showExportDialog(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseServiceProvider).db;
    final csvContent = await generateCsv(db);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        bool isSavingFile = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: LsColors.line(ctx), width: 1.2),
              ),
              backgroundColor: LsColors.surface(ctx),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: LsColors.brand.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: LsColors.brand.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.table_chart_rounded, size: 28, color: LsColors.brand),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ekspor Data CSV',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: LsColors.ink(ctx),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Data Keuangan, Tagihan, Belanja, Tabungan, dan Agenda telah dikompilasi ke format CSV.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: LsColors.mute(ctx), height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LsColors.paper(ctx),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LsColors.line(ctx)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, color: LsColors.brand, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'LifeSync_Export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: LsColors.ink(ctx)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: LsColors.brand,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isSavingFile
                            ? null
                            : () async {
                                setState(() => isSavingFile = true);
                                try {
                                  final path = await saveCsvToFile(csvContent);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('File CSV berhasil disimpan ke:\n$path'),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Gagal menyimpan file: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) setState(() => isSavingFile = false);
                                }
                              },
                        icon: isSavingFile
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_alt_rounded, size: 18),
                        label: Text(
                          isSavingFile ? 'Menyimpan...' : 'Simpan ke File Storage',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: LsColors.line(ctx), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: csvContent));
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Teks CSV berhasil disalin ke clipboard!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text(
                          'Salin Teks ke Clipboard',
                          style: TextStyle(fontWeight: FontWeight.w700, color: LsColors.ink(ctx), fontSize: 13.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Tutup', style: TextStyle(color: LsColors.mute(ctx), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
