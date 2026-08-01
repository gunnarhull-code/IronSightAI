import 'package:flutter/material.dart';

import '../../../../domain/entities/condition_rating.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/inspection.dart';
import '../../../../domain/entities/scorecard_category.dart';
import '../../../../domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import '../../../../domain/inspection_review_summary.dart';
import '../../../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../../../domain/repositories/local_inspection_repository.dart';
import 'widgets/local_only_status_banner.dart';

/// Review screen before local completion.
class InspectionReviewScreen extends StatefulWidget {
  const InspectionReviewScreen({
    super.key,
    required this.companyId,
    required this.userId,
    required this.inspectionId,
    required this.inspections,
    required this.equipmentCatalog,
  });

  final String companyId;
  final String userId;
  final String inspectionId;
  final LocalInspectionRepository inspections;
  final LocalEquipmentCatalogRepository equipmentCatalog;

  @override
  State<InspectionReviewScreen> createState() => _InspectionReviewScreenState();
}

class _InspectionReviewScreenState extends State<InspectionReviewScreen> {
  late Future<_ReviewData> _future;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReviewData> _load() async {
    final inspection = await widget.inspections.getById(
      companyId: widget.companyId,
      inspectionId: widget.inspectionId,
    );
    if (inspection == null) {
      throw StateError('Inspection not found for this company.');
    }
    final equipment = await widget.equipmentCatalog.getById(
      companyId: widget.companyId,
      equipmentId: inspection.equipmentId,
    );
    return _ReviewData(
      summary: buildInspectionReviewSummary(inspection),
      equipment: equipment,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _complete(Inspection inspection) async {
    if (_completing) return;
    final summary = buildInspectionReviewSummary(inspection);
    if (summary.hasIncompleteCategories) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete categories'),
          content: Text(
            'These categories are still not assessed:\n'
            '${summary.incompleteCategories.map((c) => c.displayLabel).join(', ')}\n\n'
            'Complete anyway? The inspection stays on this device only.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Go Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _completing = true);
    try {
      await widget.inspections.complete(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        updatedByUserId: widget.userId,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inspection completed locally'),
          content: const Text(
            'Saved on this device only. Synchronization is not available '
            'in this sprint.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on InvalidInspectionLifecycleException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not complete inspection locally.')),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: FutureBuilder<_ReviewData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load review from local storage.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final inspection = data.summary.inspection;
          final equipment = data.equipment;

          return Column(
            children: [
              LocalOnlyStatusBanner(syncStatus: inspection.syncStatus),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Equipment', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      equipment?.assetName ??
                          'Equipment ${inspection.equipmentId}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (equipment != null)
                      Text(
                        [
                          equipment.manufacturer,
                          equipment.model,
                          if (equipment.serialNumber != null)
                            'S/N ${equipment.serialNumber}',
                        ].join(' · '),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Category ratings',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final category in ScorecardCategory.scorecardOrder)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(category.displayLabel),
                        trailing: Text(
                          _ratingLabel(inspection.ratingFor(category)),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color:
                                inspection.ratingFor(category) ==
                                    ConditionRating.notAssessed
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    if (data.summary.hasIncompleteCategories) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Incomplete: '
                        '${data.summary.incompleteCategories.map((c) => c.displayLabel).join(', ')}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Detailed responses',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (inspection.detailedResponses.isEmpty)
                      const Text('No detailed responses captured.')
                    else
                      for (final entry
                          in inspection.detailedResponses.entries) ...[
                        Text(
                          entry.key.displayLabel,
                          style: theme.textTheme.titleSmall,
                        ),
                        for (final item in entry.value.items)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text(
                              '${item.labelSnapshot}: '
                              '${_ratingLabel(item.rating)}',
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    Text('Overall notes', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      (inspection.overallNotes == null ||
                              inspection.overallNotes!.trim().isEmpty)
                          ? 'None'
                          : inspection.overallNotes!,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: inspection.isIncomplete && !_completing
                          ? () => _complete(inspection)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _completing ? 'Completing…' : 'Complete locally',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _ratingLabel(ConditionRating rating) {
    return switch (rating) {
      ConditionRating.good => 'Good',
      ConditionRating.fair => 'Fair',
      ConditionRating.poor => 'Poor',
      ConditionRating.notAssessed => 'Not assessed',
    };
  }
}

class _ReviewData {
  const _ReviewData({required this.summary, required this.equipment});

  final InspectionReviewSummary summary;
  final Equipment? equipment;
}
