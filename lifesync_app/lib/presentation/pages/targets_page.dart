import 'package:lifesync_app/core/utils/translations.dart';
import 'package:lifesync_app/presentation/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/usecases/target_calculation_usecase.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/presentation/pages/target_detail_page.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

class TargetsPage extends ConsumerWidget {
  const TargetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetsAsync = ref.watch(targetsStreamProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: LsColors.paper(context),
      appBar: _buildHeader(context),
      body: targetsAsync.when(
        data: (targets) {
          if (targets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: LsColors.brand.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.savings_outlined,
                          size: 34, color: LsColors.brand),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.get(lang, 'belum_ada_target_nabung'),
                      style: TextStyle(
                        color: LsColors.ink(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.get(lang, 'buat_target_pertama'),
                      style: TextStyle(
                          color: LsColors.mute(context), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final dash = ref.watch(dashboardDataProvider).valueOrNull;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 84, top: 16),
            itemCount: targets.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _SavingsHero(
                    total: dash?.totalSavings ?? 0,
                    target: dash?.totalTargetAmount ?? 0,
                    count: targets.length,
                  ),
                );
              }
              final target = targets[index - 1];
              return _TargetCard(target: target);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: LsColors.surface(context),
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: LsColors.line(context))),
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: const Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0),
        child: LsBrandLogo(
          variant: LsLogoVariant.full,
          width: 175,
          height: 42,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class _TargetCard extends ConsumerStatefulWidget {
  final IncomeTarget target;

  const _TargetCard({required this.target});

  @override
  ConsumerState<_TargetCard> createState() => _TargetCardState();
}

class _TargetCardState extends ConsumerState<_TargetCard> {
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _loadPinnedState();
  }

  Future<void> _loadPinnedState() async {
    final ids = await HomeWidgetService.getPinnedTargetIds();
    if (mounted) {
      setState(() {
        _isPinned = ids.contains(widget.target.id);
      });
    }
  }

  Future<void> _togglePin() async {
    final result = await HomeWidgetService.togglePinTarget(widget.target.id);
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimal 3 target yang bisa di-pin ke Widget!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isPinned = result.contains(widget.target.id);
        });
        ref.invalidate(dashboardDataProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync =
        ref.watch(targetRecordsStreamProvider(widget.target.id));
    final lang = ref.watch(localeProvider).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: LsCard(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TargetDetailPage(target: widget.target)));
        },
        child: recordsAsync.when(
          data: (records) {
            final totalCollected =
                records.fold(0.0, (sum, record) => sum + record.incomeAmount);
            final progress = widget.target.targetAmount > 0
                ? (totalCollected / widget.target.targetAmount).clamp(0.0, 1.0)
                : 0.0;

            final status = TargetCalculationUseCase.determineTargetStatus(
              target: widget.target,
              collectedIncome: records,
              currentDate: DateTime.now(),
            );

            Color statusColor;
            String statusLabel;
            switch (status) {
              case TargetStatus.aheadOfSchedule:
                statusColor = LsColors.income;
                statusLabel = AppTranslations.get(lang, 'lebih_cepat');
                break;
              case TargetStatus.onTrack:
                statusColor = LsColors.brand;
                statusLabel = AppTranslations.get(lang, 'sesuai_jalur');
                break;
              case TargetStatus.behindSchedule:
                statusColor = LsColors.amber;
                statusLabel = AppTranslations.get(lang, 'tertinggal');
                break;
              case TargetStatus.completed:
                statusColor = LsColors.income;
                statusLabel = AppTranslations.get(lang, 'tercapai');
                break;
              case TargetStatus.failed:
                statusColor = LsColors.expense;
                statusLabel = AppTranslations.get(lang, 'gagal');
                break;
              case TargetStatus.active:
                statusColor = LsColors.brand;
                statusLabel = AppTranslations.get(lang, 'aktif');
                break;
              case TargetStatus.notStarted:
                statusColor = LsColors.violet;
                statusLabel = AppTranslations.get(lang, 'belum_mulai');
                break;
            }
            final money = NumberFormat('#,###', 'id_ID');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LsRing(
                      progress: progress,
                      size: 54,
                      stroke: 6,
                      color: statusColor,
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: LsColors.ink(context)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LsChip(statusLabel, color: statusColor),
                          const SizedBox(height: 3),
                          Text(
                            widget.target.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: LsColors.ink(context)),
                          ),
                          Text(
                            '${DateFormat('d MMM').format(widget.target.startDate)} – ${DateFormat('d MMM yyyy').format(widget.target.endDate)}',
                            style: TextStyle(
                                fontSize: 11, color: LsColors.mute(context)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _togglePin,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isPinned
                              ? LsColors.brand
                              : LsColors.brand.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 16,
                          color:
                              _isPinned ? Colors.white : LsColors.mute(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: LsColors.line(context)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppTranslations.get(lang, 'terkumpul'),
                            style: TextStyle(
                                fontSize: 11, color: LsColors.mute(context))),
                        Text.rich(TextSpan(children: [
                          TextSpan(
                            text: 'Rp ${money.format(totalCollected.toInt())}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: LsColors.income),
                          ),
                          TextSpan(
                            text:
                                '  / Rp ${money.format(widget.target.targetAmount.toInt())}',
                            style: TextStyle(
                                fontSize: 11.5, color: LsColors.mute(context)),
                          ),
                        ])),
                      ],
                    ),
                    LsChip(
                      widget.target.mode == 'fixed'
                          ? 'Tetap Rp ${money.format(widget.target.fixedDailyAmount)}/hari'
                          : 'Nominal Bebas',
                      color: LsColors.brand,
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e, st) => const Text('Error loading progress'),
        ),
      ),
    );
  }
}

class _SavingsHero extends ConsumerWidget {
  final double total;
  final double target;
  final int count;
  const _SavingsHero(
      {required this.total, required this.target, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final pct = target > 0 ? (total / target).clamp(0.0, 1.0) : 0.0;
    final money = NumberFormat('#,###', 'id_ID');
    return LsHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LsEyebrow(
              '${AppTranslations.get(lang, 'total_tabungan')} · $count target',
              color: const Color(0xA6FFFFFF)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rp ${money.format(total.toInt())}',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: const Color(0xFF6EE7B7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(pct * 100).round()}% ${AppTranslations.get(lang, 'dari_total_target')} Rp ${money.format(target.toInt())}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xB3FFFFFF)),
          ),
        ],
      ),
    );
  }
}
