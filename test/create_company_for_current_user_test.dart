import 'package:flutter_test/flutter_test.dart';

import 'package:ironsight_ai/domain/entities/country_catalog.dart';
import 'package:ironsight_ai/domain/use_cases/create_company_for_current_user.dart';

import 'support/fake_company_repository.dart';

void main() {
  test('CreateCompanyForCurrentUser rejects blank names', () async {
    final repository = FakeCompanyRepository();
    final useCase = CreateCompanyForCurrentUser(repository);

    expect(() => useCase(name: '   '), throwsArgumentError);
    expect(repository.createCallCount, 0);
    expect(repository.updateCallCount, 0);
  });

  test(
    'CreateCompanyForCurrentUser trims and defaults country to US',
    () async {
      final repository = FakeCompanyRepository();
      final useCase = CreateCompanyForCurrentUser(repository);

      final company = await useCase(name: '  Hull Equipment  ');

      expect(company.name, 'Hull Equipment');
      expect(company.region, defaultCompanyCountry);
      expect(repository.createCallCount, 1);
      expect(repository.updateCallCount, 1);
      expect(repository.lastCreatedName, 'Hull Equipment');
      expect(repository.lastUpdatedRegion, defaultCompanyCountry);
    },
  );
}
