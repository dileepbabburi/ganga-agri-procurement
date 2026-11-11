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

    test('calculates good seed, one-month interest, and one receipt deduction', () {
      final record = Weighment(
        id: 'record-3',
        farmerId: 'farmer-3',
        farmerName: 'Test Farmer',
        farmerMobile: '9876543210',
        crop: 'Maize',
        bagWeights: const [],
        grossWeightKg: 3270,
        bagCount: 56,
        weightEntryMode: 'gross',
        gunnyPerBagKg: 1,
        kadthaKg: 0,
        ratePerQuintal: 2500,
        interestRatePercent: 2,
        receiptType: 'AR',
        receiptPerBag: 10,
        createdAt: DateTime.utc(2026, 11, 11),
      );

      expect(record.bagCount, 56);
      expect(record.grossWeightKg, 3270);
      expect(record.gunnyDeductionKg, 56);
      expect(record.goodSeedWeightKg, 3214);
      expect(record.grossPayment, 80350);
      expect(record.interestAmount, 1607);
      expect(record.receiptTotal, 560);
      expect(record.finalPayable, 78183);

      final restored = Weighment.fromMap(record.toMap());
      expect(restored.weightEntryMode, 'gross');
      expect(restored.bagCount, 56);
      expect(restored.goodSeedWeightKg, 3214);
      expect(restored.interestAmount, 1607);
      expect(restored.receiptType, 'AR');
      expect(restored.receiptTotal, 560);
      expect(restored.finalPayable, 78183);
    });

    test('supports individual bag weights, Kadtha, and HR instead of AR', () {
      final record = Weighment(
        id: 'record-4',
        farmerId: 'farmer-4',
        farmerName: 'Test Farmer',
        farmerMobile: '9876543210',
        crop: 'Paddy',
        bagWeights: [100, 100],
        createdAt: DateTime.utc(2026, 11, 11),
        gunnyPerBagKg: 1,
        kadthaKg: 3,
        ratePerQuintal: 2000,
        interestRatePercent: 2,
        receiptType: 'HR',
        receiptPerBag: 20,
      );

      expect(record.grossWeightKg, 200);
      expect(record.gunnyDeductionKg, 2);
      expect(record.goodSeedWeightKg, 195);
      expect(record.grossPayment, 3900);
      expect(record.interestAmount, 78);
      expect(record.receiptTotal, 40);
      expect(record.finalPayable, 3782);
    });

    test('reads records created before payment fields existed', () {
      final oldRecord = Weighment(
        id: 'record-old',
        farmerId: 'farmer-old',
        farmerName: 'Test Farmer',
        farmerMobile: '9876543210',
        crop: 'Paddy',
        bagWeights: [45, 47],
        createdAt: DateTime.utc(2026, 11, 10),
      ).toMap()
        ..remove('bagCount')
        ..remove('weightEntryMode')
        ..remove('gunnyPerBagKg')
        ..remove('kadthaKg')
        ..remove('ratePerQuintal')
        ..remove('interestRatePercent')
        ..remove('receiptType')
        ..remove('receiptPerBag');

      final restored = Weighment.fromMap(oldRecord);
      expect(restored.bagCount, 2);
      expect(restored.grossWeightKg, 92);
      expect(restored.goodSeedWeightKg, 92);
      expect(restored.finalPayable, 0);
    });
  });
}
