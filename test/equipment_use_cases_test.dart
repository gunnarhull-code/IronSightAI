import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/manufacturer_catalog.dart';
import 'package:ironsight_ai/domain/exceptions/duplicate_serial_number_exception.dart';
import 'package:ironsight_ai/domain/use_cases/create_equipment.dart';
import 'package:ironsight_ai/domain/use_cases/delete_equipment.dart';
import 'package:ironsight_ai/domain/use_cases/get_equipment_by_id.dart';
import 'package:ironsight_ai/domain/use_cases/get_equipment_list.dart';
import 'package:ironsight_ai/domain/use_cases/update_equipment.dart';

import 'support/fake_equipment_repository.dart';

void main() {
  Equipment sampleEquipment({String id = 'equipment-1', String? serialNumber}) {
    return Equipment(
      id: id,
      companyId: 'company-1',
      assetName: 'Excavator 1',
      manufacturer: 'Caterpillar',
      model: '320',
      serialNumber: serialNumber,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  group('GetEquipmentList', () {
    test('returns equipment from the repository', () async {
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment()],
      );
      final useCase = GetEquipmentList(repository);

      final result = await useCase();

      expect(result, hasLength(1));
      expect(result.first.assetName, 'Excavator 1');
    });

    test('returns an empty list when the company has no equipment', () async {
      final repository = FakeEquipmentRepository();
      final useCase = GetEquipmentList(repository);

      final result = await useCase();

      expect(result, isEmpty);
    });
  });

  group('GetEquipmentById', () {
    test('returns null when not found', () async {
      final repository = FakeEquipmentRepository();
      final useCase = GetEquipmentById(repository);

      expect(await useCase('missing'), isNull);
    });

    test('returns the matching equipment', () async {
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment(id: 'equipment-42')],
      );
      final useCase = GetEquipmentById(repository);

      final result = await useCase('equipment-42');

      expect(result?.id, 'equipment-42');
    });
  });

  group('CreateEquipment', () {
    test('creates equipment with valid required fields', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);

      final created = await useCase(
        assetName: '  Skid Steer  ',
        manufacturer: ' Bobcat ',
        model: ' S650 ',
        serialNumber: '  ABC123  ',
        year: 2020,
        hours: 1500.5,
        location: ' Lot A ',
        notes: ' Good condition ',
      );

      expect(created.assetName, 'Skid Steer');
      expect(created.manufacturer, 'Bobcat');
      expect(created.model, 'S650');
      expect(repository.createCallCount, 1);
      expect(repository.lastCreatedDetails?.serialNumber, 'ABC123');
      expect(repository.lastCreatedDetails?.location, 'Lot A');
    });

    test(
      'uppercases model letters while preserving digits and punctuation',
      () async {
        final repository = FakeEquipmentRepository();
        final useCase = CreateEquipment(repository);

        final created = await useCase(
          assetName: 'Loader',
          manufacturer: 'Caterpillar',
          model: 'ab-12.3x',
        );

        expect(created.model, 'AB-12.3X');
        expect(repository.lastCreatedDetails?.model, 'AB-12.3X');
      },
    );

    test('rejects a blank asset name', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);

      expect(
        () => useCase(
          assetName: '   ',
          manufacturer: 'Caterpillar',
          model: '320',
        ),
        throwsArgumentError,
      );
      expect(repository.createCallCount, 0);
    });

    test('rejects a blank manufacturer', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);

      expect(
        () => useCase(assetName: 'Loader', manufacturer: '  ', model: '320'),
        throwsArgumentError,
      );
      expect(repository.createCallCount, 0);
    });

    test('rejects a manufacturer not in the catalog', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);

      expect(
        () => useCase(
          assetName: 'Loader',
          manufacturer: 'Acme Machines',
          model: '320',
        ),
        throwsArgumentError,
      );
      expect(repository.createCallCount, 0);
    });

    test('accepts every catalog manufacturer', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);

      for (final manufacturer in manufacturerCatalog) {
        final created = await useCase(
          assetName: 'Loader',
          manufacturer: manufacturer,
          model: '320',
        );
        expect(created.manufacturer, manufacturer);
      }
      expect(repository.createCallCount, manufacturerCatalog.length);
    });

    test('rejects a blank model', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);

      expect(
        () => useCase(
          assetName: 'Loader',
          manufacturer: 'Caterpillar',
          model: '   ',
        ),
        throwsArgumentError,
      );
      expect(repository.createCallCount, 0);
    });

    test('rejects a negative hours value', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);

      expect(
        () => useCase(
          assetName: 'Loader',
          manufacturer: 'Caterpillar',
          model: '320',
          hours: -1,
        ),
        throwsArgumentError,
      );
      expect(repository.createCallCount, 0);
    });

    test('rejects a year earlier than 1950', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);

      expect(
        () => useCase(
          assetName: 'Loader',
          manufacturer: 'Caterpillar',
          model: '320',
          year: 1949,
        ),
        throwsArgumentError,
      );
      expect(repository.createCallCount, 0);
    });

    test('rejects a year later than next year', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);
      final tooLate = DateTime.now().year + 2;

      expect(
        () => useCase(
          assetName: 'Loader',
          manufacturer: 'Caterpillar',
          model: '320',
          year: tooLate,
        ),
        throwsArgumentError,
      );
      expect(repository.createCallCount, 0);
    });

    test('accepts the year boundary values', () async {
      final repository = FakeEquipmentRepository();
      final useCase = CreateEquipment(repository);
      final maxYear = DateTime.now().year + 1;

      final earliest = await useCase(
        assetName: 'Loader',
        manufacturer: 'Caterpillar',
        model: '320',
        year: 1950,
      );
      final latest = await useCase(
        assetName: 'Loader',
        manufacturer: 'Caterpillar',
        model: '320',
        year: maxYear,
      );

      expect(earliest.year, 1950);
      expect(latest.year, maxYear);
    });

    test(
      'rejects a serial number already used by another company equipment',
      () async {
        final repository = FakeEquipmentRepository(
          equipment: [sampleEquipment(serialNumber: 'ABC123')],
        );
        final useCase = CreateEquipment(repository);

        expect(
          () => useCase(
            assetName: 'Loader',
            manufacturer: 'Caterpillar',
            model: '320',
            serialNumber: 'ABC123',
          ),
          throwsA(isA<DuplicateSerialNumberException>()),
        );
        expect(repository.createCallCount, 0);
      },
    );

    test('allows a serial number that is not already used', () async {
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment(serialNumber: 'ABC123')],
      );
      final useCase = CreateEquipment(repository);

      final created = await useCase(
        assetName: 'Loader',
        manufacturer: 'Caterpillar',
        model: '320',
        serialNumber: 'XYZ999',
      );

      expect(created.serialNumber, 'XYZ999');
      expect(repository.createCallCount, 1);
    });

    test(
      'does not check for duplicates when no serial number is given',
      () async {
        final repository = FakeEquipmentRepository();
        final useCase = CreateEquipment(repository);

        await useCase(
          assetName: 'Loader',
          manufacturer: 'Caterpillar',
          model: '320',
        );

        expect(repository.isSerialNumberTakenCallCount, 0);
        expect(repository.createCallCount, 1);
      },
    );
  });

  group('UpdateEquipment', () {
    test('updates equipment with valid fields', () async {
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment()],
      );
      final useCase = UpdateEquipment(repository);

      final updated = await useCase(
        id: 'equipment-1',
        assetName: 'Excavator 1 (Refurbished)',
        manufacturer: 'Caterpillar',
        model: '320',
      );

      expect(updated.assetName, 'Excavator 1 (Refurbished)');
      expect(repository.updateCallCount, 1);
      expect(repository.lastUpdatedId, 'equipment-1');
    });

    test(
      'rejects a blank required field before calling the repository',
      () async {
        final repository = FakeEquipmentRepository(
          equipment: [sampleEquipment()],
        );
        final useCase = UpdateEquipment(repository);

        expect(
          () => useCase(
            id: 'equipment-1',
            assetName: '',
            manufacturer: 'Caterpillar',
            model: '320',
          ),
          throwsArgumentError,
        );
        expect(repository.updateCallCount, 0);
      },
    );

    test('rejects a manufacturer not in the catalog', () async {
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment()],
      );
      final useCase = UpdateEquipment(repository);

      expect(
        () => useCase(
          id: 'equipment-1',
          assetName: 'Excavator 1',
          manufacturer: 'Acme Machines',
          model: '320',
        ),
        throwsArgumentError,
      );
      expect(repository.updateCallCount, 0);
    });

    test(
      'allows keeping the same serial number when editing that record',
      () async {
        final repository = FakeEquipmentRepository(
          equipment: [sampleEquipment(serialNumber: 'ABC123')],
        );
        final useCase = UpdateEquipment(repository);

        final updated = await useCase(
          id: 'equipment-1',
          assetName: 'Excavator 1',
          manufacturer: 'Caterpillar',
          model: '320',
          serialNumber: 'ABC123',
        );

        expect(updated.serialNumber, 'ABC123');
        expect(repository.updateCallCount, 1);
      },
    );

    test(
      'rejects a serial number already used by a different record',
      () async {
        final repository = FakeEquipmentRepository(
          equipment: [
            sampleEquipment(id: 'equipment-1', serialNumber: 'ABC123'),
            sampleEquipment(id: 'equipment-2', serialNumber: 'XYZ999'),
          ],
        );
        final useCase = UpdateEquipment(repository);

        expect(
          () => useCase(
            id: 'equipment-1',
            assetName: 'Excavator 1',
            manufacturer: 'Caterpillar',
            model: '320',
            serialNumber: 'XYZ999',
          ),
          throwsA(isA<DuplicateSerialNumberException>()),
        );
        expect(repository.updateCallCount, 0);
      },
    );

    test('surfaces repository failures', () async {
      final repository = FakeEquipmentRepository(equipment: [sampleEquipment()])
        ..updateError = Exception('network unavailable');
      final useCase = UpdateEquipment(repository);

      await expectLater(
        useCase(
          id: 'equipment-1',
          assetName: 'Excavator 1',
          manufacturer: 'Caterpillar',
          model: '320',
        ),
        throwsException,
      );
      expect(repository.updateCallCount, 1);
    });
  });

  group('DeleteEquipment', () {
    test('deletes the requested equipment through the repository', () async {
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment(id: 'equipment-1')],
      );
      final useCase = DeleteEquipment(repository);

      await useCase('equipment-1');

      expect(repository.deleteCallCount, 1);
      expect(repository.lastDeletedId, 'equipment-1');
      expect(repository.equipment, isEmpty);
    });

    test('rejects a blank id before calling the repository', () async {
      final repository = FakeEquipmentRepository(
        equipment: [sampleEquipment(id: 'equipment-1')],
      );
      final useCase = DeleteEquipment(repository);

      expect(() => useCase('   '), throwsArgumentError);
      expect(repository.deleteCallCount, 0);
      expect(repository.equipment, hasLength(1));
    });
  });
}
