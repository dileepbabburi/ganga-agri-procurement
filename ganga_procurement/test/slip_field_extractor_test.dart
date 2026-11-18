import 'package:flutter_test/flutter_test.dart';
import 'package:ganga_procurement/data/slip_field_extractor.dart';

void main() {
  test(
    'extracts labeled farmer, bag count, rate, crop and numbered weights',
    () {
      final draft = extractSlipDraft('''
Farmer Name: Example Farmer
Mobile No: 9876543210
Crop: Maize
Total Bags: 3
Rate per Quintal: 2450
1. 52.5
2. 51
3. 49.75
''');

      expect(draft.farmerName, 'Example Farmer');
      expect(draft.mobile, '9876543210');
      expect(draft.crop, 'Maize');
      expect(draft.bagCount, 3);
      expect(draft.rate, 2450);
      expect(draft.bagWeights, [52.5, 51, 49.75]);
    },
  );

  test('does not guess unlabeled amounts as farmer, rate or bag weights', () {
    final draft = extractSlipDraft('''
Ganga Agri Genetics
2450
1782
34
''');

    expect(draft.farmerName, isNull);
    expect(draft.rate, isNull);
    expect(draft.bagCount, isNull);
    expect(draft.bagWeights, isEmpty);
  });

  test(
    'derives bag count from consecutive numbered weights when count is absent',
    () {
      final draft = extractSlipDraft('1. 48\n2. 50\n3. 51');
      expect(draft.bagCount, 3);
      expect(draft.bagWeights, [48, 50, 51]);
    },
  );
}
