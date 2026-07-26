import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/equipment.dart';
import '../../domain/entities/equipment_details.dart';
import '../../domain/repositories/equipment_repository.dart';

/// Supabase-backed [EquipmentRepository].
///
/// Every query resolves the current user's `company_id` from `user_profiles`
/// (never from UI input) and filters by it explicitly, in addition to the
/// `company_id`-based Row Level Security policies on `public.equipment` —
/// RLS is the actual tenant-isolation boundary; the explicit filter here is
/// defense in depth, matching [SupabaseCompanyRepository]'s pattern.
class SupabaseEquipmentRepository implements EquipmentRepository {
  SupabaseEquipmentRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, company_id, asset_name, manufacturer, model, serial_number, '
      'year, hours, location, notes, created_by, updated_by, '
      'created_at, updated_at';

  Future<String> _requireCurrentCompanyId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not authenticated');
    }

    final profile = await _client
        .from('user_profiles')
        .select('company_id')
        .eq('id', userId)
        .maybeSingle();

    final companyId = profile?['company_id'] as String?;
    if (companyId == null) {
      throw StateError('Current user does not belong to a company');
    }
    return companyId;
  }

  @override
  Future<List<Equipment>> getEquipment() async {
    final companyId = await _requireCurrentCompanyId();

    final rows = await _client
        .from('equipment')
        .select(_columns)
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return _equipmentFromRows(rows as List);
  }

  @override
  Future<Equipment?> getEquipmentById(String id) async {
    final companyId = await _requireCurrentCompanyId();

    final row = await _client
        .from('equipment')
        .select(_columns)
        .eq('id', id)
        .eq('company_id', companyId)
        .maybeSingle();

    if (row == null) return null;
    return (await _equipmentFromRows([row])).single;
  }

  @override
  Future<Equipment> createEquipment(EquipmentDetails details) async {
    final companyId = await _requireCurrentCompanyId();

    final row = await _client
        .from('equipment')
        .insert({'company_id': companyId, ..._detailsToMap(details)})
        .select(_columns)
        .single();

    return (await _equipmentFromRows([row])).single;
  }

  @override
  Future<Equipment> updateEquipment(String id, EquipmentDetails details) async {
    final companyId = await _requireCurrentCompanyId();

    final row = await _client
        .from('equipment')
        .update(_detailsToMap(details))
        .eq('id', id)
        .eq('company_id', companyId)
        .select(_columns)
        .single();

    return (await _equipmentFromRows([row])).single;
  }

  @override
  Future<void> deleteEquipment(String id) async {
    final companyId = await _requireCurrentCompanyId();

    await _client
        .from('equipment')
        .delete()
        .eq('id', id)
        .eq('company_id', companyId);
  }

  @override
  Future<bool> isSerialNumberTaken(
    String serialNumber, {
    String? excludeEquipmentId,
  }) async {
    final companyId = await _requireCurrentCompanyId();

    final query = _client
        .from('equipment')
        .select('id')
        .eq('company_id', companyId)
        .eq('serial_number', serialNumber);

    final rows = excludeEquipmentId == null
        ? await query
        : await query.neq('id', excludeEquipmentId);

    return (rows as List).isNotEmpty;
  }

  Map<String, dynamic> _detailsToMap(EquipmentDetails details) {
    return {
      'asset_name': details.assetName,
      'manufacturer': details.manufacturer,
      'model': details.model,
      'serial_number': details.serialNumber,
      'year': details.year,
      'hours': details.hours,
      'location': details.location,
      'notes': details.notes,
    };
  }

  Future<List<Equipment>> _equipmentFromRows(List rows) async {
    final mappedRows = rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final userIds = <String>{
      for (final row in mappedRows) ...[
        if (row['created_by'] case final String id) id,
        if (row['updated_by'] case final String id) id,
      ],
    };
    final namesById = await _profileNamesById(userIds);

    return mappedRows.map((row) {
      return Equipment.fromMap({
        ...row,
        'created_by_name': namesById[row['created_by']],
        'updated_by_name': namesById[row['updated_by']],
      });
    }).toList();
  }

  Future<Map<String, String>> _profileNamesById(Set<String> userIds) async {
    if (userIds.isEmpty) return const {};

    final rows = await _client
        .from('user_profiles')
        .select('id, full_name')
        .inFilter('id', userIds.toList());

    return {
      for (final row in rows as List)
        if (row case {'id': final String id, 'full_name': final String name})
          id: name,
    };
  }
}
