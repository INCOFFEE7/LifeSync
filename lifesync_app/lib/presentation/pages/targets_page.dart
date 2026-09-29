import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifesync_app/domain/entities/income_target.dart';
import 'package:lifesync_app/domain/usecases/target_calculation_usecase.dart';
import 'package:lifesync_app/presentation/providers/repository_providers.dart';
import 'package:lifesync_app/presentation/providers/dashboard_provider.dart';
import 'package:lifesync_app/presentation/pages/create_target_page.dart';
import 'package:lifesync_app/presentation/pages/target_detail_page.dart';
import 'package:lifesync_app/core/services/home_widget_service.dart';
import 'package:intl/intl.dart';

class TargetsPage extends ConsumerWidget {
  const TargetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetsAsync = ref.watch(targetsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildHeader(),
      body: targetsAsync.when(
        data: (targets) {
          if (targets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Belum ada target nabung.', style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Buat target nabung pertama Anda untuk mulai menabung!'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];
              return _TargetCard(target: target);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'targets_fab',
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTargetPage()));
        },
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Buat Target Nabung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );

  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.white,
      scrolledUnderElevation: 4,
      titleSpacing: 20,
      title: Image.asset(
        'assets/images/logofull.png',
        width: 140,
        cacheWidth: 420,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (c, e, s) => const Text(
          'LifeSync',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
            letterSpacing: -0.5,
          ),
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
    final result = await HomeWidgetService.togglePinTarget(widget.target.id!);
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
    final recordsAsync = ref.watch(targetRecordsStreamProvider(widget.target.id!));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TargetDetailPage(target: widget.target)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: recordsAsync.when(
            data: (records) {
              double totalCollected = records.fold(0.0, (sum, record) => sum + record.incomeAmount);
              double progress = widget.target.targetAmount > 0 ? (totalCollected / widget.target.targetAmount).clamp(0.0, 1.0) : 0;

              TargetStatus status = TargetCalculationUseCase.determineTargetStatus(
                target: widget.target,
                collectedIncome: records,
                currentDate: DateTime.now(),
              );

              Color statusColor;
              switch (status) {
                case TargetStatus.aheadOfSchedule: statusColor = Colors.green; break;
                case TargetStatus.onTrack: statusColor = Colors.blue; break;
                case TargetStatus.behindSchedule: statusColor = Colors.orange; break;
                case TargetStatus.completed: statusColor = Colors.teal; break;
                case TargetStatus.failed: statusColor = Colors.red; break;
                case TargetStatus.active: statusColor = Colors.blue; break;
                case TargetStatus.notStarted: statusColor = Colors.grey; break;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.target.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Pin toggle button
                      GestureDetector(
                        onTap: _togglePin,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(7),
                          margin: const EdgeInsets.only(left: 8, right: 4),
                          decoration: BoxDecoration(
                            color: _isPinned ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 15,
                            color: _isPinned ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.target.mode == 'fixed'
                          ? 'Nominal Tetap: Rp ${NumberFormat('#,###', 'id_ID').format(widget.target.fixedDailyAmount)}/hari'
                          : 'Nominal Bebas',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rp${NumberFormat('#,###').format(totalCollected)}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      Text('of Rp${NumberFormat('#,###').format(widget.target.targetAmount)}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${DateFormat('MMM d').format(widget.target.startDate)} - ${DateFormat('MMM d, yyyy').format(widget.target.endDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (e, st) => const Text('Error loading progress'),
          ),
        ),
      ),
    );
  }
}
