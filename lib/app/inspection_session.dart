import '../data/local/offline_inspection_workspace.dart';

/// Active company/user + offline workspace for inspection routes.
class InspectionSession {
  const InspectionSession({
    required this.companyId,
    required this.userId,
    required this.workspace,
  });

  final String companyId;
  final String userId;
  final OfflineInspectionWorkspace workspace;
}
