import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../app/router.dart';
import '../../../../data/ai/create_walkaround_video_bindings.dart';
import '../../../../data/equipment_id_capture/camera_capture_page.dart';
import '../../../../data/equipment_id_capture/create_platform_bindings.dart';
import '../../../../domain/ai/ai_service.dart';
import '../../../../domain/ai/walkaround_video_capture_port.dart';
import '../../../../domain/entities/condition_rating.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/guided_quick_appraisal_step.dart';
import '../../../../domain/entities/inspection.dart';
import '../../../../domain/entities/inspection_machine_source.dart';
import '../../../../domain/entities/inspection_media.dart';
import '../../../../domain/entities/inspection_photo_slot.dart';
import '../../../../domain/entities/scorecard_category.dart';
import '../../../../domain/equipment_id_capture/camera_permission_port.dart';
import '../../../../domain/equipment_id_capture/captured_image.dart';
import '../../../../domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import '../../../../domain/equipment_id_capture/equipment_id_capture_controller.dart';
import '../../../../domain/equipment_id_capture/equipment_id_capture_failure.dart';
import '../../../../domain/equipment_id_capture/equipment_id_capture_kind.dart';
import '../../../../domain/equipment_id_capture/image_capture_port.dart';
import '../../../../domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import '../../../../domain/guided_quick_appraisal_completeness.dart';
import '../../../../domain/repositories/local_equipment_catalog_repository.dart';
import '../../../../domain/repositories/local_inspection_media_repository.dart';
import '../../../../domain/repositories/local_inspection_repository.dart';
import '../../equipment_id_capture/presentation/equipment_id_capture_panel.dart';
import 'ai_media_review_labels.dart';
import 'ai_media_review_screen.dart';
import 'inspection_workspace_screen.dart'
    show EquipmentIdCaptureControllerFactory;
import 'widgets/condition_rating_controls.dart';
import 'widgets/local_only_status_banner.dart';
import 'widgets/required_inspection_photos_section.dart';

/// Guided step-by-step Quick Appraisal intake.
class GuidedQuickAppraisalScreen extends StatefulWidget {
  const GuidedQuickAppraisalScreen({
    super.key,
    required this.companyId,
    required this.userId,
    required this.inspectionId,
    required this.inspections,
    required this.equipmentCatalog,
    required this.inspectionMedia,
    this.navigatorKey,
    this.captureControllerFactory,
    this.imageCapture,
    this.cameraPermission,
    this.aiService,
    this.videoCapture,
    this.initialStepOverride,
  });

  final String companyId;
  final String userId;
  final String inspectionId;
  final LocalInspectionRepository inspections;
  final LocalEquipmentCatalogRepository equipmentCatalog;
  final LocalInspectionMediaRepository inspectionMedia;
  final GlobalKey<NavigatorState>? navigatorKey;
  final EquipmentIdCaptureControllerFactory? captureControllerFactory;
  final ImageCapturePort? imageCapture;
  final CameraPermissionPort? cameraPermission;

  /// Optional cloud AI adapter. Never a vendor SDK. Never required.
  final AIService? aiService;

  /// Optional walkaround recorder override for tests.
  final WalkaroundVideoCapturePort? videoCapture;

  /// Test-only: force the first visible step instead of resume resolution.
  final GuidedQuickAppraisalStep? initialStepOverride;

  @override
  State<GuidedQuickAppraisalScreen> createState() =>
      _GuidedQuickAppraisalScreenState();
}

class _GuidedQuickAppraisalScreenState
    extends State<GuidedQuickAppraisalScreen> {
  late Future<_GuidedData> _future;
  GuidedQuickAppraisalStep? _step;
  bool _stepInitialized = false;

  final TextEditingController _assetNameController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _mutating = false;
  bool _savingNotes = false;
  bool _savingEquipmentId = false;
  bool _completing = false;
  bool _legacyRedirectScheduled = false;
  InspectionPhotoSlot? _busyPhotoSlot;
  final Map<InspectionPhotoSlot, Uint8List> _previewBytes = {};

  EquipmentIdCaptureController? _serialController;
  EquipmentIdCaptureController? _hoursController;
  ImageCapturePort? _photoCapture;
  CameraPermissionPort? _photoPermission;

  List<Equipment> _catalog = const [];

  @override
  void initState() {
    super.initState();
    _future = _load(initializeStep: true);
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    _serialController?.dispose();
    _hoursController?.dispose();
    super.dispose();
  }

  ImageCapturePort get _resolvedPhotoCapture {
    final existing = _photoCapture;
    if (existing != null) return existing;
    if (widget.imageCapture != null) {
      return _photoCapture = widget.imageCapture!;
    }
    final nav = widget.navigatorKey;
    if (nav != null) {
      return _photoCapture = NavigatorCameraImageCapture(
        navigatorKey: nav,
        pageTitle: 'Capture required photo',
      );
    }
    final bindings = createPlatformEquipmentIdCaptureBindings(
      navigatorKey: widget.navigatorKey,
    );
    return _photoCapture = bindings.imageCapture;
  }

  CameraPermissionPort get _resolvedPhotoPermission {
    final existing = _photoPermission;
    if (existing != null) return existing;
    if (widget.cameraPermission != null) {
      return _photoPermission = widget.cameraPermission!;
    }
    final bindings = createPlatformEquipmentIdCaptureBindings(
      navigatorKey: widget.navigatorKey,
    );
    return _photoPermission = bindings.cameraPermission;
  }

  EquipmentIdCaptureController _createController({
    required EquipmentIdCaptureKind kind,
    ConfirmedEquipmentIdValue? initialConfirmed,
  }) {
    final factory = widget.captureControllerFactory;
    if (factory != null) {
      return factory(kind: kind, initialConfirmed: initialConfirmed);
    }
    final bindings = createPlatformEquipmentIdCaptureBindings(
      navigatorKey: widget.navigatorKey,
    );
    return EquipmentIdCaptureController(
      kind: kind,
      imageCapture: bindings.imageCapture,
      textRecognition: bindings.textRecognition,
      cameraPermission: bindings.cameraPermission,
      initialConfirmed: initialConfirmed,
    );
  }

  void _ensureCaptureControllers(Inspection inspection) {
    _serialController ??= _createController(
      kind: EquipmentIdCaptureKind.serialNumber,
      initialConfirmed: inspection.confirmedSerialNumber,
    );
    _hoursController ??= _createController(
      kind: EquipmentIdCaptureKind.hourMeter,
      initialConfirmed: inspection.confirmedHourMeter,
    );
  }

  Future<_GuidedData> _load({bool initializeStep = false}) async {
    final inspection = await widget.inspections.getById(
      companyId: widget.companyId,
      inspectionId: widget.inspectionId,
    );
    if (inspection == null) {
      throw StateError('Inspection not found for this company.');
    }

    // Defensive: never convert or complete legacy drafts in the guided flow.
    if (inspection.isLegacyDraft) {
      _scheduleLegacyWorkspaceRedirect();
    }

    final equipmentId = inspection.equipmentId;
    final equipment = equipmentId == null || equipmentId.isEmpty
        ? null
        : await widget.equipmentCatalog.getById(
            companyId: widget.companyId,
            equipmentId: equipmentId,
          );

    if (_assetNameController.text != (inspection.pendingAssetName ?? '')) {
      _assetNameController.text = inspection.pendingAssetName ?? '';
    }
    if (_manufacturerController.text !=
        (inspection.pendingManufacturer ?? '')) {
      _manufacturerController.text = inspection.pendingManufacturer ?? '';
    }
    if (_modelController.text != (inspection.pendingModel ?? '')) {
      _modelController.text = inspection.pendingModel ?? '';
    }
    if (_notesController.text != (inspection.overallNotes ?? '')) {
      _notesController.text = inspection.overallNotes ?? '';
    }

    _ensureCaptureControllers(inspection);

    final mediaList = await widget.inspectionMedia.listForInspection(
      companyId: widget.companyId,
      inspectionId: widget.inspectionId,
    );
    final mediaBySlot = <InspectionPhotoSlot, InspectionMedia>{
      for (final item in mediaList) item.slot: item,
    };
    await _hydratePreviews(mediaBySlot);

    _catalog = await widget.equipmentCatalog.listForCompany(widget.companyId);

    final completeness = evaluateGuidedQuickAppraisalCompleteness(
      inspection: inspection,
      media: mediaList,
    );

    if (initializeStep && !_stepInitialized) {
      _step =
          widget.initialStepOverride ??
          resolveGuidedResumeStep(inspection: inspection, media: mediaList);
      _stepInitialized = true;
    }

    return _GuidedData(
      inspection: inspection,
      equipment: equipment,
      mediaBySlot: mediaBySlot,
      mediaList: mediaList,
      completeness: completeness,
    );
  }

  Future<void> _hydratePreviews(
    Map<InspectionPhotoSlot, InspectionMedia> mediaBySlot,
  ) async {
    final next = <InspectionPhotoSlot, Uint8List>{};
    for (final entry in mediaBySlot.entries) {
      final cached = _previewBytes[entry.key];
      if (cached != null && cached.length == entry.value.byteSize) {
        next[entry.key] = cached;
        continue;
      }
      try {
        final image = await widget.inspectionMedia.loadCapturedImage(
          companyId: widget.companyId,
          media: entry.value,
        );
        next[entry.key] = Uint8List.fromList(image.bytes);
      } catch (_) {
        // Preview is best-effort.
      }
    }
    _previewBytes
      ..clear()
      ..addAll(next);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openAiMediaReview() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AiMediaReviewScreen(
          companyId: widget.companyId,
          inspectionId: widget.inspectionId,
          userId: widget.userId,
          aiService: widget.aiService ?? const UnavailableAIService(),
          inspections: widget.inspections,
          inspectionMedia: widget.inspectionMedia,
          videoCapture:
              widget.videoCapture ??
              createWalkaroundVideoCapturePort(
                navigatorKey: widget.navigatorKey,
              ),
        ),
      ),
    );
    if (mounted) _reload();
  }

  Widget _optionalAiReviewEntry({
    required bool editable,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: AiMediaReviewLabels.actionButton,
          child: OutlinedButton.icon(
            onPressed: editable ? _openAiMediaReview : null,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text(AiMediaReviewLabels.actionButton),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Optional AI suggestions from photos and extracted walkaround '
          'frames. Never required. Quick Appraisal works offline without AI.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _scheduleLegacyWorkspaceRedirect() {
    if (_legacyRedirectScheduled) return;
    _legacyRedirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.inspectionWorkspace(widget.inspectionId),
      );
    });
  }

  void _announceSaveError(String message) {
    _announceForAccessibility(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            if (_mutating || _savingNotes) return;
            _saveAndExit();
          },
        ),
      ),
    );
  }

  void _announceForAccessibility(String message) {
    final view = View.maybeOf(context);
    if (view != null) {
      SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
    }
  }

  GuidedQuickAppraisalStep get _currentStep =>
      _step ?? GuidedQuickAppraisalStep.machineSource;

  Future<void> _persistStep(GuidedQuickAppraisalStep step) async {
    await widget.inspections.updateGuidedIntake(
      companyId: widget.companyId,
      inspectionId: widget.inspectionId,
      updatedByUserId: widget.userId,
      guidedStep: step,
    );
  }

  Future<void> _goToStep(GuidedQuickAppraisalStep step) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await _persistStep(step);
      if (!mounted) return;
      setState(() => _step = step);
      _reload();
    } catch (_) {
      if (!mounted) return;
      const message =
          'Could not save step progress locally. Stay here and retry.';
      _announceForAccessibility(message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _saveAndExit() async {
    if (_mutating || _savingNotes || _savingEquipmentId) return;
    setState(() => _mutating = true);
    try {
      await _persistStep(_currentStep);
      if (_currentStep == GuidedQuickAppraisalStep.equipmentIdentity) {
        final ok = await _persistPendingIdentity(
          reload: false,
          announceError: false,
        );
        if (!ok) {
          if (!mounted) return;
          _announceSaveError(
            'Could not save equipment identity locally. Stay here and retry.',
          );
          return;
        }
      }
      if (_currentStep == GuidedQuickAppraisalStep.notes) {
        await _saveNotesSilently();
      }
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } catch (_) {
      if (!mounted) return;
      _announceSaveError(
        'Could not save this step locally. Stay here and retry.',
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<bool> _persistCurrentStepEdits() async {
    if (_currentStep == GuidedQuickAppraisalStep.equipmentIdentity) {
      return _persistPendingIdentity(reload: false);
    }
    if (_currentStep == GuidedQuickAppraisalStep.notes) {
      try {
        await _saveNotesSilently();
        return true;
      } catch (_) {
        if (!mounted) return false;
        const message = 'Could not save notes locally. Stay here and retry.';
        _announceForAccessibility(message);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(message)));
        return false;
      }
    }
    return true;
  }

  Future<void> _onBack(Inspection inspection) async {
    if (_mutating || _savingNotes) return;
    final previous = _currentStep.previous;
    if (previous == null) {
      await _saveAndExit();
      return;
    }
    final ok = await _persistCurrentStepEdits();
    if (!ok) return;
    await _goToStep(previous);
  }

  Future<void> _onNext(Inspection inspection) async {
    if (_mutating || _savingNotes) return;
    final ok = await _persistCurrentStepEdits();
    if (!ok) return;
    final next = _currentStep.next;
    if (next == null) return;
    await _goToStep(next);
  }

  Future<bool> _persistPendingIdentity({
    required bool reload,
    bool announceError = true,
  }) async {
    final data = await _future;
    final inspection = data.inspection;
    if (!inspection.isIncomplete || inspection.isDiscarded) return true;

    // Only New-machine guided drafts edit pending identity here.
    if (inspection.machineSource != InspectionMachineSource.newMachine) {
      return true;
    }

    final name = _assetNameController.text.trim();
    final manufacturer = _manufacturerController.text.trim();
    final model = _modelController.text.trim().toUpperCase();
    if (_modelController.text != model) {
      _modelController.value = TextEditingValue(
        text: model,
        selection: TextSelection.collapsed(offset: model.length),
      );
    }
    try {
      await widget.inspections.updateGuidedIntake(
        companyId: widget.companyId,
        inspectionId: widget.inspectionId,
        updatedByUserId: widget.userId,
        pendingAssetName: name.isEmpty ? null : name,
        pendingManufacturer: manufacturer.isEmpty ? null : manufacturer,
        pendingModel: model.isEmpty ? null : model,
        guidedStep: _currentStep,
      );
      if (reload && mounted) _reload();
      return true;
    } catch (_) {
      if (!mounted) return false;
      if (announceError) {
        const message = 'Could not save equipment identity locally.';
        _announceForAccessibility(message);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(message)));
      }
      return false;
    }
  }

  Future<void> _setMachineSource(InspectionMachineSource source) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      if (source == InspectionMachineSource.newMachine) {
        await widget.inspections.updateGuidedIntake(
          companyId: widget.companyId,
          inspectionId: widget.inspectionId,
          updatedByUserId: widget.userId,
          machineSource: source,
          clearEquipmentId: true,
          guidedStep: GuidedQuickAppraisalStep.machineSource,
        );
      } else {
        await widget.inspections.updateGuidedIntake(
          companyId: widget.companyId,
          inspectionId: widget.inspectionId,
          updatedByUserId: widget.userId,
          machineSource: source,
          clearPendingIdentity: true,
          guidedStep: GuidedQuickAppraisalStep.machineSource,
        );
      }
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update machine source.')),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _selectExistingEquipment(Equipment equipment) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await widget.inspections.updateGuidedIntake(
        companyId: widget.companyId,
        inspectionId: widget.inspectionId,
        updatedByUserId: widget.userId,
        machineSource: InspectionMachineSource.existingEquipment,
        equipmentId: equipment.id,
        clearPendingIdentity: true,
        guidedStep: GuidedQuickAppraisalStep.equipmentIdentity,
      );
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not link equipment locally.')),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _persistEquipmentId(
    Inspection inspection,
    ConfirmedEquipmentIdValue confirmed,
  ) async {
    final alreadyPersisted = switch (confirmed.kind) {
      EquipmentIdCaptureKind.serialNumber =>
        inspection.serialNumber == confirmed.value &&
            inspection.serialCaptureMethod == confirmed.method,
      EquipmentIdCaptureKind.hourMeter =>
        inspection.hourMeterReading == confirmed.hours &&
            inspection.hourMeterCaptureMethod == confirmed.method,
    };
    if (alreadyPersisted) return;

    setState(() => _savingEquipmentId = true);
    try {
      await widget.inspections.saveConfirmedEquipmentId(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        confirmedValue: confirmed,
        updatedByUserId: widget.userId,
      );
      if (mounted) _reload();
    } finally {
      if (mounted) setState(() => _savingEquipmentId = false);
    }
  }

  Future<void> _markSerialUnableToVerify(Inspection inspection) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await widget.inspections.markSerialUnableToVerify(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        updatedByUserId: widget.userId,
      );
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark serial unable to verify.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _markHoursUnavailable(Inspection inspection) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await widget.inspections.markHoursUnavailable(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        updatedByUserId: widget.userId,
      );
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark hours unavailable.')),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<CapturedImage?> _captureStillImage() async {
    final permission = await _resolvedPhotoPermission.request();
    if (permission == CameraPermissionStatus.denied ||
        permission == CameraPermissionStatus.permanentlyDenied ||
        permission == CameraPermissionStatus.restricted ||
        permission == CameraPermissionStatus.unavailable) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            permission == CameraPermissionStatus.denied ||
                    permission == CameraPermissionStatus.permanentlyDenied
                ? EquipmentIdCaptureFailure.permissionDenied().message
                : EquipmentIdCaptureFailure.cameraUnavailable().message,
          ),
        ),
      );
      return null;
    }

    try {
      final image = await _resolvedPhotoCapture.captureStill();
      if (image.isEmpty) return null;
      return image;
    } on EquipmentIdCaptureException catch (error) {
      if (!mounted) return null;
      if (error.failure.kind !=
          EquipmentIdCaptureFailureKind.captureCancelled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.failure.message)));
      }
      return null;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not capture photo.')));
      return null;
    }
  }

  Future<void> _saveRequiredPhoto(
    Inspection inspection,
    InspectionPhotoSlot slot, {
    required bool runOcrWhenApplicable,
  }) async {
    if (_busyPhotoSlot != null ||
        !inspection.isIncomplete ||
        inspection.isDiscarded) {
      return;
    }

    setState(() => _busyPhotoSlot = slot);
    try {
      final image = await _captureStillImage();
      if (image == null) return;

      await widget.inspectionMedia.saveRequiredPhoto(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        slot: slot,
        image: image,
        updatedByUserId: widget.userId,
      );

      if (runOcrWhenApplicable) {
        await _recognizeRequiredPhoto(slot, image);
      }

      if (mounted) _reload();
    } on InvalidInspectionLifecycleException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save photo locally.')),
      );
    } finally {
      if (mounted) setState(() => _busyPhotoSlot = null);
    }
  }

  Future<void> _recognizeRequiredPhoto(
    InspectionPhotoSlot slot,
    CapturedImage image,
  ) async {
    if (slot.feedsSerialOcr) {
      await _serialController?.recognizeExistingImage(image);
    } else if (slot.feedsHourMeterOcr) {
      await _hoursController?.recognizeExistingImage(image);
    }
  }

  Future<void> _scanOcrFromRequiredPhoto(
    Inspection inspection,
    EquipmentIdCaptureKind kind,
  ) async {
    final slot = kind == EquipmentIdCaptureKind.serialNumber
        ? InspectionPhotoSlot.serialDataPlate
        : InspectionPhotoSlot.hourMeterDashboard;
    final controller = kind == EquipmentIdCaptureKind.serialNumber
        ? _serialController
        : _hoursController;
    if (controller == null) return;

    final existing = await widget.inspectionMedia.getBySlot(
      companyId: widget.companyId,
      inspectionId: inspection.id,
      slot: slot,
    );
    if (existing != null) {
      try {
        final image = await widget.inspectionMedia.loadCapturedImage(
          companyId: widget.companyId,
          media: existing,
        );
        await controller.recognizeExistingImage(image);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the required photo for OCR.'),
          ),
        );
      }
      return;
    }

    await _saveRequiredPhoto(inspection, slot, runOcrWhenApplicable: true);
  }

  void _previewPhoto(InspectionPhotoSlot slot) {
    final bytes = _previewBytes[slot];
    if (bytes == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _saveRating(
    Inspection inspection,
    ScorecardCategory category,
    ConditionRating rating,
  ) async {
    if (_mutating || !inspection.isIncomplete || inspection.isDiscarded) return;
    setState(() => _mutating = true);
    try {
      await widget.inspections.saveCategoryRating(
        companyId: widget.companyId,
        inspectionId: inspection.id,
        category: category,
        rating: rating,
        updatedByUserId: widget.userId,
      );
      if (mounted) _reload();
    } on InvalidInspectionLifecycleException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save rating locally.')),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _saveNotesSilently() async {
    final text = _notesController.text.trim();
    await widget.inspections.updateMetadata(
      companyId: widget.companyId,
      inspectionId: widget.inspectionId,
      updatedByUserId: widget.userId,
      overallNotes: text.isEmpty ? null : text,
      clearOverallNotes: text.isEmpty,
    );
  }

  Future<void> _saveNotes(Inspection inspection) async {
    if (_savingNotes) return;
    setState(() => _savingNotes = true);
    try {
      await _saveNotesSilently();
      if (mounted) _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save notes locally.')),
      );
    } finally {
      if (mounted) setState(() => _savingNotes = false);
    }
  }

  Future<void> _complete(Inspection inspection) async {
    if (_completing) return;
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
      _reload();
    } on InvalidInspectionLifecycleException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not complete. Your draft remains available to resume.',
          ),
        ),
      );
      _reload();
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
      _reload();
    }
  }

  String _requirementLabel(GuidedQuickAppraisalRequirement requirement) {
    return switch (requirement) {
      GuidedQuickAppraisalRequirement.machineSource => 'Machine source',
      GuidedQuickAppraisalRequirement.equipmentIdentity => 'Equipment identity',
      GuidedQuickAppraisalRequirement.requiredPhotos => 'Required photos',
      GuidedQuickAppraisalRequirement.serial => 'Serial number',
      GuidedQuickAppraisalRequirement.hours => 'Hour meter',
      GuidedQuickAppraisalRequirement.conditionRatings => 'Condition ratings',
    };
  }

  GuidedQuickAppraisalStep _stepForRequirement(
    GuidedQuickAppraisalRequirement requirement,
  ) {
    return switch (requirement) {
      GuidedQuickAppraisalRequirement.machineSource =>
        GuidedQuickAppraisalStep.machineSource,
      GuidedQuickAppraisalRequirement.equipmentIdentity =>
        GuidedQuickAppraisalStep.equipmentIdentity,
      GuidedQuickAppraisalRequirement.requiredPhotos =>
        GuidedQuickAppraisalStep.requiredPhotos,
      GuidedQuickAppraisalRequirement.serial ||
      GuidedQuickAppraisalRequirement.hours =>
        GuidedQuickAppraisalStep.serialAndHours,
      GuidedQuickAppraisalRequirement.conditionRatings =>
        GuidedQuickAppraisalStep.quickCondition,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _currentStep;

    return Scaffold(
      appBar: AppBar(
        title: Text(step.title),
        actions: [
          TextButton(
            onPressed: (_mutating || _savingNotes || _savingEquipmentId)
                ? null
                : _saveAndExit,
            child: const Text('Save and exit'),
          ),
        ],
      ),
      body: FutureBuilder<_GuidedData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not open this guided draft.',
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
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final inspection = data.inspection;
          if (inspection.isLegacyDraft) {
            return const Center(child: CircularProgressIndicator());
          }
          final editable = inspection.isIncomplete && !inspection.isDiscarded;

          return Column(
            children: [
              LocalOnlyStatusBanner(syncStatus: inspection.syncStatus),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    label: 'Step ${step.stepNumber} of ${step.totalSteps}',
                    child: Text(
                      'Step ${step.stepNumber} of ${step.totalSteps}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _buildStepBody(
                      theme: theme,
                      data: data,
                      editable: editable,
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _buildBottomActions(
                    theme: theme,
                    inspection: inspection,
                    editable: editable,
                    completeness: data.completeness,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomActions({
    required ThemeData theme,
    required Inspection inspection,
    required bool editable,
    required GuidedQuickAppraisalCompleteness completeness,
  }) {
    final isLast = _currentStep == GuidedQuickAppraisalStep.reviewAndComplete;
    return Row(
      children: [
        OutlinedButton(
          onPressed: _mutating || _completing
              ? null
              : () => _onBack(inspection),
          child: const Text('Back'),
        ),
        const Spacer(),
        if (!isLast)
          FilledButton(
            onPressed: editable && !_mutating && !_completing
                ? () => _onNext(inspection)
                : null,
            child: const Text('Next'),
          )
        else
          FilledButton(
            onPressed:
                editable &&
                    !_mutating &&
                    !_completing &&
                    completeness.isComplete
                ? () => _complete(inspection)
                : null,
            child: Text(_completing ? 'Completing…' : 'Complete'),
          ),
      ],
    );
  }

  Widget _buildStepBody({
    required ThemeData theme,
    required _GuidedData data,
    required bool editable,
  }) {
    final inspection = data.inspection;
    return switch (_currentStep) {
      GuidedQuickAppraisalStep.machineSource => _buildMachineSourceStep(
        theme,
        inspection,
        editable,
      ),
      GuidedQuickAppraisalStep.equipmentIdentity => _buildIdentityStep(
        theme,
        data,
        editable,
      ),
      GuidedQuickAppraisalStep.requiredPhotos => _buildPhotosStep(
        theme,
        data,
        editable,
      ),
      GuidedQuickAppraisalStep.serialAndHours => _buildSerialHoursStep(
        theme,
        data,
        editable,
      ),
      GuidedQuickAppraisalStep.quickCondition => _buildConditionStep(
        theme,
        inspection,
        editable,
      ),
      GuidedQuickAppraisalStep.notes => _buildNotesStep(
        theme,
        inspection,
        editable,
      ),
      GuidedQuickAppraisalStep.reviewAndComplete => _buildReviewStep(
        theme,
        data,
        editable,
      ),
    };
  }

  Widget _buildMachineSourceStep(
    ThemeData theme,
    Inspection inspection,
    bool editable,
  ) {
    final selected = inspection.machineSource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Is this a new machine or existing equipment?',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final source in InspectionMachineSource.values) ...[
          Card(
            color: selected == source
                ? theme.colorScheme.primaryContainer
                : null,
            child: ListTile(
              enabled: editable && !_mutating,
              title: Text(source.displayLabel),
              subtitle: Text(
                source == InspectionMachineSource.newMachine
                    ? 'Create equipment when you complete this appraisal'
                    : 'Link to equipment already cached on this device',
              ),
              trailing: selected == source
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () => _setMachineSource(source),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (selected != null)
          Text(
            'Changing source clears the other path’s identity fields.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildIdentityStep(ThemeData theme, _GuidedData data, bool editable) {
    final inspection = data.inspection;
    final isNew =
        inspection.machineSource == InspectionMachineSource.newMachine;

    if (isNew) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the machine identity',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _assetNameController,
            enabled: editable && !_mutating,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Asset name',
            ),
            onEditingComplete: () => _persistPendingIdentity(reload: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manufacturerController,
            enabled: editable && !_mutating,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Manufacturer',
            ),
            onEditingComplete: () => _persistPendingIdentity(reload: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            enabled: editable && !_mutating,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [_UppercaseLettersFormatter()],
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Model',
              helperText: 'Model letters are saved uppercase',
            ),
            onEditingComplete: () => _persistPendingIdentity(reload: true),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Select existing equipment', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Showing equipment cached on this device.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (_catalog.isEmpty)
          const Text('No equipment is cached on this device yet.')
        else
          for (final item in _catalog) ...[
            Card(
              color: inspection.equipmentId == item.id
                  ? theme.colorScheme.primaryContainer
                  : null,
              child: ListTile(
                enabled: editable && !_mutating,
                onTap: () => _selectExistingEquipment(item),
                title: Text(item.assetName),
                subtitle: Text(
                  [
                    item.manufacturer,
                    item.model,
                    if (item.serialNumber != null) 'S/N ${item.serialNumber}',
                  ].join(' · '),
                ),
                trailing: inspection.equipmentId == item.id
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    : const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildPhotosStep(ThemeData theme, _GuidedData data, bool editable) {
    final inspection = data.inspection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: !editable || _busyPhotoSlot != null,
          child: Opacity(
            opacity: editable && _busyPhotoSlot == null ? 1 : 0.6,
            child: RequiredInspectionPhotosSection(
              mediaBySlot: data.mediaBySlot,
              previewBytesBySlot: Map.unmodifiable(_previewBytes),
              enabled: editable,
              busySlot: _busyPhotoSlot,
              onCapture: (slot) => _saveRequiredPhoto(
                inspection,
                slot,
                runOcrWhenApplicable: true,
              ),
              onRetake: (slot) => _saveRequiredPhoto(
                inspection,
                slot,
                runOcrWhenApplicable: true,
              ),
              onPreview: _previewPhoto,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _optionalAiReviewEntry(editable: editable, theme: theme),
      ],
    );
  }

  Widget _buildSerialHoursStep(
    ThemeData theme,
    _GuidedData data,
    bool editable,
  ) {
    final inspection = data.inspection;
    final serialController = _serialController;
    final hoursController = _hoursController;
    if (serialController == null || hoursController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Serial number and hours', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Scan or type values. OCR reuses the required serial/hour photos.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: !editable || _savingEquipmentId,
          child: Opacity(
            opacity: editable && !_savingEquipmentId ? 1 : 0.6,
            child: EquipmentIdCapturePanel(
              key: const ValueKey('guided-serial-capture'),
              controller: serialController,
              onScanRequested: () => _scanOcrFromRequiredPhoto(
                inspection,
                EquipmentIdCaptureKind.serialNumber,
              ),
              onPersist: (value) => _persistEquipmentId(inspection, value),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: editable && !_mutating
              ? () => _markSerialUnableToVerify(inspection)
              : null,
          child: Text(
            inspection.serialIsUnableToVerify
                ? 'Serial: unable to verify (selected)'
                : 'Unable to verify',
          ),
        ),
        const SizedBox(height: 16),
        IgnorePointer(
          ignoring: !editable || _savingEquipmentId,
          child: Opacity(
            opacity: editable && !_savingEquipmentId ? 1 : 0.6,
            child: EquipmentIdCapturePanel(
              key: const ValueKey('guided-hours-capture'),
              controller: hoursController,
              onScanRequested: () => _scanOcrFromRequiredPhoto(
                inspection,
                EquipmentIdCaptureKind.hourMeter,
              ),
              onPersist: (value) => _persistEquipmentId(inspection, value),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: editable && !_mutating
              ? () => _markHoursUnavailable(inspection)
              : null,
          child: Text(
            inspection.hoursAreUnavailable
                ? 'Hours: unavailable / not displayed (selected)'
                : 'Unavailable / not displayed',
          ),
        ),
      ],
    );
  }

  Widget _buildConditionStep(
    ThemeData theme,
    Inspection inspection,
    bool editable,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quick condition', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Rate each category. Not assessed is allowed.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final category in ScorecardCategory.scorecardOrder) ...[
          Text(category.displayLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ConditionRatingControls(
            value: inspection.ratingFor(category),
            enabled: editable && !_mutating,
            includeNotAssessed: true,
            onChanged: (rating) => _saveRating(inspection, category, rating),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildNotesStep(
    ThemeData theme,
    Inspection inspection,
    bool editable,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Notes (optional)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          enabled: editable && !_savingNotes,
          minLines: 4,
          maxLines: 8,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Optional notes (saved on this device)',
          ),
          onEditingComplete: () => _saveNotes(inspection),
          onTapOutside: (_) => _saveNotes(inspection),
        ),
      ],
    );
  }

  Widget _buildReviewStep(ThemeData theme, _GuidedData data, bool editable) {
    final inspection = data.inspection;
    final equipment = data.equipment;
    final completeness = data.completeness;

    final identityTitle = inspection.isNewMachineDraft
        ? (inspection.pendingAssetName?.trim().isNotEmpty == true
              ? inspection.pendingAssetName!
              : 'New machine draft')
        : (equipment?.assetName ??
              'Equipment ${inspection.equipmentId ?? 'unknown'}');

    final identityDetail = inspection.isNewMachineDraft
        ? [
            inspection.pendingManufacturer,
            inspection.pendingModel,
          ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ')
        : [
            if (equipment != null) ...[equipment.manufacturer, equipment.model],
          ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Review & Complete', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Text('Identity', style: theme.textTheme.titleSmall),
        Text(identityTitle, style: theme.textTheme.titleLarge),
        if (identityDetail.isNotEmpty) Text(identityDetail),
        const SizedBox(height: 16),
        Text('Required photos', style: theme.textTheme.titleSmall),
        for (final slot in InspectionPhotoSlot.requiredSlots)
          Text(
            '${slot.label}: '
            '${data.mediaBySlot.containsKey(slot) ? 'Completed' : 'Missing'}',
          ),
        const SizedBox(height: 16),
        _optionalAiReviewEntry(editable: editable, theme: theme),
        const SizedBox(height: 16),
        Text('Serial & hours', style: theme.textTheme.titleSmall),
        Text(
          inspection.serialIsUnableToVerify
              ? 'Serial: Unable to verify'
              : (inspection.serialNumber == null
                    ? 'Serial: Missing'
                    : 'Serial: ${inspection.serialNumber}'),
        ),
        Text(
          inspection.hoursAreUnavailable
              ? 'Hours: Unavailable / not displayed'
              : (inspection.hourMeterReading == null
                    ? 'Hours: Missing'
                    : 'Hours: ${inspection.confirmedHourMeter?.value ?? inspection.hourMeterReading}'),
        ),
        const SizedBox(height: 16),
        Text('Condition ratings', style: theme.textTheme.titleSmall),
        for (final category in ScorecardCategory.scorecardOrder)
          Text(
            '${category.displayLabel}: '
            '${_ratingLabel(inspection.ratingFor(category))}',
          ),
        const SizedBox(height: 16),
        Text('Notes', style: theme.textTheme.titleSmall),
        Text(
          (inspection.overallNotes == null ||
                  inspection.overallNotes!.trim().isEmpty)
              ? 'None'
              : inspection.overallNotes!,
        ),
        if (!completeness.isComplete) ...[
          const SizedBox(height: 20),
          Text(
            'Missing requirements',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          for (final requirement in completeness.missing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(_requirementLabel(requirement)),
              trailing: const Icon(Icons.chevron_right),
              onTap: editable
                  ? () => _goToStep(_stepForRequirement(requirement))
                  : null,
            ),
          if (completeness.missingPhotoSlots.isNotEmpty)
            Text(
              'Photos: ${completeness.missingPhotoSlots.map((s) => s.label).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ],
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

class _GuidedData {
  const _GuidedData({
    required this.inspection,
    required this.equipment,
    required this.mediaBySlot,
    required this.mediaList,
    required this.completeness,
  });

  final Inspection inspection;
  final Equipment? equipment;
  final Map<InspectionPhotoSlot, InspectionMedia> mediaBySlot;
  final List<InspectionMedia> mediaList;
  final GuidedQuickAppraisalCompleteness completeness;
}

/// Forces letter characters to uppercase while preserving digits/symbols.
class _UppercaseLettersFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    for (final unit in newValue.text.runes) {
      final char = String.fromCharCode(unit);
      buffer.write(char.toUpperCase());
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
