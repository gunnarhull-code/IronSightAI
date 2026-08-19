import 'package:flutter/material.dart';

import '../../../../domain/entities/condition_rating.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/inspection.dart';
import '../../../../domain/entities/scorecard_category.dart';
import '../../../../domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import '../../../../domain/guided_quick_appraisal_completeness.dart';
import '../../../../domain/inspection_review_summary.dart';
import '../../../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../../../domain/repositories/local_inspection_media_repository.dart';
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
    this.inspectionMedia,
  });

  final String companyId;
  final String userId;
  final String inspectionId;
  final LocalInspectionRepository inspections;
  final LocalEquipmentCatalogRepository equipmentCatalog;

  /// Optional; when present, guided drafts use completeness gating in UI.
  final LocalInspectionMediaRepository? inspectionMedia;

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
    final equipmentId = inspection.equipmentId;
    final equipment = equipmentId == null || equipmentId.isEmpty
        ? null
        : await widget.equipmentCatalog.getById(
            companyId: widget.companyId,
            equipmentId: equipmentId,
          );

    GuidedQuickAppraisalCompleteness? guidedCompleteness;
    final mediaRepo = widget.inspectionMedia;
    if (mediaRepo != null && inspection.machineSource != null) {
      final media = await mediaRepo.listForInspection(
        companyId: widget.companyId,
        inspectionId: widget.inspectionId,
      );
      guidedCompleteness = evaluateGuidedQuickAppraisalCompleteness(
        inspection: inspection,
        media: media,
      );
    }

    return _ReviewData(
      summary: buildInspectionReviewSummary(inspection),
      equipment: equipment,
      guidedCompleteness: guidedCompleteness,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _complete(Inspection inspection) async {
    if (_completing) return;

    final data = await _future;
    if (!mounted) return;
    final guided = data.guidedCompleteness;
    if (guided != null && !guided.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Guided Quick Appraisal is incomplete. Return to the guided '
            'flow to finish required steps.',
          ),
        ),
      );
      return;
    }

    final summary = buildInspectionReviewSummary(inspection);
    if (guided == null && summary.hasIncompleteCategories) {
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
    } on DuplicateLocalEquipmentSerialException catch (error) {
      if (!mounted) return;
      await _handleDuplicateSerial(inspection, error);
    } on GuidedQuickAppraisalIncompleteException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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

  Future<void> _handleDuplicateSerial(
    Inspection inspection,
    DuplicateLocalEquipmentSerialException error,
  ) async {
    final decision = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Serial already on device'),
        content: Text(
          'Serial ${error.serialNumber} matches existing equipment on this '
          'device. Switch this draft to that equipment and complete, or cancel '
          'and keep this draft resumable?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch & complete'),
          ),
        ],
      ),
    );
    if (decision != true || !mounted) return;

    try {
      await widget.inspections.switchGuidedDraftToExistingEquipment(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        equipmentId: error.existingEquipmentId,
        updatedByUserId: widget.userId,
      );
      await widget.inspections.completeGuidedExistingEquipment(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        updatedByUserId: widget.userId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not switch to existing equipment. Draft remains resumable.',
          ),
        ),
      );
    }
  }

  String _identityTitle(Inspection inspection, Equipment? equipment) {
    if (inspection.isNewMachineDraft) {
      final pending = inspection.pendingAssetName?.trim();
      if (pending != null && pending.isNotEmpty) return pending;
      return 'New machine draft';
    }
    return equipment?.assetName ??
        'Equipment ${inspection.equipmentId ?? 'unknown'}';
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
          final guided = data.guidedCompleteness;
          final canComplete =
              inspection.isIncomplete &&
              !_completing &&
              (guided == null || guided.isComplete);

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
                      _identityTitle(inspection, equipment),
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (equipment != null)
                      Text(
                        [
                          equipment.manufacturer,
                          equipment.model,
                          if (equipment.serialNumber != null)
                            'Catalog S/N ${equipment.serialNumber}',
                        ].join(' · '),
                      ),
                    if (inspection.serialNumber != null ||
                        inspection.hourMeterReading != null ||
                        inspection.serialIsUnableToVerify ||
                        inspection.hoursAreUnavailable) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Confirmed for this inspection',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      if (inspection.serialIsUnableToVerify)
                        const Text('Serial: Unable to verify')
                      else if (inspection.serialNumber != null)
                        Text('Serial: ${inspection.serialNumber}'),
                      if (inspection.hoursAreUnavailable)
                        const Text('Hours: Unavailable / not displayed')
                      else if (inspection.hourMeterReading != null)
                        Text(
                          'Hours: ${inspection.confirmedHourMeter?.value ?? inspection.hourMeterReading}',
                        ),
                    ],
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
                    if (guided != null && !guided.isComplete) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Guided intake incomplete. Open the guided Quick '
                        'Appraisal to finish required steps.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ] else if (data.summary.hasIncompleteCategories) ...[
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
                      onPressed: canComplete
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
  const _ReviewData({
    required this.summary,
    required this.equipment,
    this.guidedCompleteness,
  });

  final InspectionReviewSummary summary;
  final Equipment? equipment;
  final GuidedQuickAppraisalCompleteness? guidedCompleteness;
}
