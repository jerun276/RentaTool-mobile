import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/equipment_history_model.dart';
import '../models/inspection_log_model.dart';
import '../providers/catalog_provider.dart';
import '../widgets/wear_progress_bar.dart';

class EquipmentHistoryScreen extends ConsumerWidget {
  final String equipmentId;

  const EquipmentHistoryScreen({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(equipmentHistoryProvider(equipmentId));
    final dateFormatter = DateFormat('MMM dd, yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance & History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Timeline',
            onPressed: () => ref.invalidate(equipmentHistoryProvider(equipmentId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.fact_check_outlined, size: 18),
        label: const Text('New Inspection'),
        onPressed: () async {
          await context.push('/catalog/inspection/$equipmentId');
          ref.invalidate(equipmentHistoryProvider(equipmentId));
        },
      ),
      body: historyAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading maintenance history...'),
        error: (err, _) => ErrorView(
          message: 'Failed to load maintenance timeline.',
          onRetry: () => ref.invalidate(equipmentHistoryProvider(equipmentId)),
        ),
        data: (history) => _buildTimelineContent(context, history, dateFormatter),
      ),
    );
  }

  Widget _buildTimelineContent(
    BuildContext context,
    EquipmentHistoryTimelineModel history,
    DateFormat dateFormatter,
  ) {
    final isLockout = history.isLockoutTriggered;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Machine Overview & Wear Status Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        history.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    StatusBadge(
                      label: isLockout ? 'LOCKOUT TRIGGERED' : 'OPERATIONAL',
                      style: isLockout ? BadgeStyle.error : BadgeStyle.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Wear status progress
                WearProgressBar(daysAccumulated: history.totalRentalDays),
                const SizedBox(height: 12),

                // Servicing date info
                Row(
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Text(
                      history.lastServicingDateUtc != null
                          ? 'Last Serviced: ${dateFormatter.format(DateTime.tryParse(history.lastServicingDateUtc!) ?? DateTime.now())}'
                          : 'No documented prior servicing',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),

                if (isLockout) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x22EF4444),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.wearLockout),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.wearLockout, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mandatory Servicing Required. Machine has accumulated 60+ rental days and is locked out from new bookings.',
                            style: TextStyle(color: AppColors.wearLockout, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Timeline Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'INSPECTION & CONDITION AUDIT LOGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              '${history.inspectionTimeline.length} records',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Timeline Items
        if (history.inspectionTimeline.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.assignment_outlined, size: 40, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'No condition inspection records logged yet.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...history.inspectionTimeline.map((log) => _buildTimelineCard(log, dateFormatter)),
      ],
    );
  }

  Widget _buildTimelineCard(InspectionLogModel log, DateFormat dateFormatter) {
    final dateStr = log.createdAtUtc != null
        ? dateFormatter.format(DateTime.tryParse(log.createdAtUtc!) ?? DateTime.now())
        : 'Unknown Date';

    final badgeStyle = log.isSevereOrCritical
        ? BadgeStyle.error
        : (log.severity.toLowerCase() == 'moderate'
            ? BadgeStyle.warning
            : BadgeStyle.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: log.isSevereOrCritical ? AppColors.wearLockout : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.inspectionType.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primaryLight,
                ),
              ),
              StatusBadge(label: 'SEVERITY: ${log.severity}', style: badgeStyle),
            ],
          ),
          const SizedBox(height: 6),
          Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),

          // Condition Notes
          Text(
            log.conditionNotes,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Multi-Angle Photos
          if (log.photos.isNotEmpty) ...[
            const Text(
              'PHOTOGRAPHIC EVIDENCE BY ANGLE',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: log.photos.length,
                itemBuilder: (context, idx) {
                  final photo = log.photos[idx];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photo.photoUrl.isNotEmpty)
                          Image.network(
                            photo.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined, size: 24, color: AppColors.textMuted),
                            ),
                          )
                        else
                          const Center(
                            child: Icon(Icons.camera_alt_outlined, size: 24, color: AppColors.textMuted),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: const Color(0xCC000000),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              photo.angle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
