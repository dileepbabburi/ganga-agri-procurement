import 'package:flutter_test/flutter_test.dart';
import 'package:ganga_procurement/models.dart';

void main() {
  group('Weighment', () {
    test('adds individual bag weights to get the gross total', () {
      final record = Weighment(
        id: 'record-1',
        farmerId: 'farmer-1',
        farmerName: 'Test Farmer',
        farmerMobile: '9876543210',
        crop: 'Maize',
        bagWeights: [51.25, 48.75, 50],
        createdAt: DateTime.utc(2026, 11, 10),
      );

      expect(record.bagCount, 3);
      expect(record.grossWeightKg, 150);
    });

    test('keeps the same bag weights and offline status after storage round trip', () {
      final record = Weighment(
        id: 'record-2',
        farmerId: 'farmer-2',
        farmerName: 'Test Farmer',
        farmerMobile: '9876543210',
        crop: 'Paddy',
        bagWeights: [44.5, 47],
        createdAt: DateTime.utc(2026, 11, 10, 8, 30),
        slipPhotoBase64: 'c2xpcA==',
      );

      final restored = Weighment.fromMap(record.toMap());

      expect(restored.bagWeights, [44.5, 47]);
      expect(restored.grossWeightKg, 91.5);
      expect(restored.synced, isFalse);
      expect(restored.approvedByRole, 'worker');
      expect(restored.slipPhotoBase64, 'c2xpcA==');
      expect(restored.createdAt, record.createdAt);
    });
  });
}
