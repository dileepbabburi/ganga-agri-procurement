// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

class Farmer {
  const Farmer({
    required this.id,
    required this.name,
    required this.mobile,
    this.village = '',
  });

  final String id;
  final String name;
  final String mobile;
  final String village;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'village': village,
      };

  factory Farmer.fromMap(Map<String, Object?> map) => Farmer(
        id: map['id']! as String,
        name: map['name']! as String,
        mobile: map['mobile']! as String,
        village: map['village'] as String? ?? '',
      );
}

class Weighment {
  const Weighment({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmerMobile,
    required this.crop,
    required this.bagWeights,
    required this.createdAt,
    double? grossWeightKg,
    int? bagCount,
    this.weightEntryMode = 'individual',
    this.gunnyPerBagKg = 0,
    this.kadthaKg = 0,
    this.ratePerQuintal = 0,
    this.interestRatePercent = 0,
    this.receiptType = '',
    this.receiptPerBag = 0,
    this.approvedByRole = 'worker',
    this.slipPhotoBase64,
    this.synced = false,
  })  : _grossWeightKg = grossWeightKg,
        _bagCount = bagCount;

  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerMobile;
  final String crop;
  final List<double> bagWeights;
  final DateTime createdAt;
  final double? _grossWeightKg;
  final int? _bagCount;
  final String weightEntryMode;
  final double gunnyPerBagKg;
  final double kadthaKg;
  final double ratePerQuintal;
  final double interestRatePercent;
  final String receiptType;
  final double receiptPerBag;
  final String approvedByRole;
  final String? slipPhotoBase64;
  final bool synced;

  double get grossWeightKg =>
      _grossWeightKg ?? bagWeights.fold(0, (sum, weight) => sum + weight);
  int get bagCount => (_bagCount ?? 0) > 0 ? _bagCount! : bagWeights.length;
  double get gunnyDeductionKg => bagCount * gunnyPerBagKg;
  double get goodSeedWeightKg => grossWeightKg - gunnyDeductionKg - kadthaKg;
  double get grossPayment => goodSeedWeightKg / 100 * ratePerQuintal;
  double get interestAmount => grossPayment * interestRatePercent / 100;
  double get receiptTotal => bagCount * receiptPerBag;
  double get finalPayable => grossPayment - interestAmount - receiptTotal;

  Map<String, Object?> toMap() => {
        'id': id,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'farmerMobile': farmerMobile,
        'crop': crop,
        'bagWeights': jsonEncode(bagWeights),
        'grossWeightKg': grossWeightKg,
        'bagCount': bagCount,
        'weightEntryMode': weightEntryMode,
        'gunnyPerBagKg': gunnyPerBagKg,
        'kadthaKg': kadthaKg,
        'ratePerQuintal': ratePerQuintal,
        'interestRatePercent': interestRatePercent,
        'receiptType': receiptType,
        'receiptPerBag': receiptPerBag,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'approvedByRole': approvedByRole,
        'slipPhotoBase64': slipPhotoBase64,
        'synced': synced ? 1 : 0,
      };

  factory Weighment.fromMap(Map<String, Object?> map) => Weighment(
        id: map['id']! as String,
        farmerId: map['farmerId']! as String,
        farmerName: map['farmerName']! as String,
        farmerMobile: map['farmerMobile']! as String,
        crop: map['crop']! as String,
        bagWeights: (jsonDecode(map['bagWeights']! as String) as List<dynamic>)
            .map((value) => (value as num).toDouble())
            .toList(),
        createdAt: DateTime.parse(map['createdAt']! as String),
        grossWeightKg: (map['grossWeightKg'] as num?)?.toDouble(),
        bagCount: (map['bagCount'] as num?)?.toInt(),
        weightEntryMode: map['weightEntryMode'] as String? ?? 'individual',
        gunnyPerBagKg: (map['gunnyPerBagKg'] as num?)?.toDouble() ?? 0,
        kadthaKg: (map['kadthaKg'] as num?)?.toDouble() ?? 0,
        ratePerQuintal: (map['ratePerQuintal'] as num?)?.toDouble() ?? 0,
        interestRatePercent:
            (map['interestRatePercent'] as num?)?.toDouble() ?? 0,
        receiptType: map['receiptType'] as String? ?? '',
        receiptPerBag: (map['receiptPerBag'] as num?)?.toDouble() ?? 0,
        approvedByRole: map['approvedByRole'] as String? ?? 'worker',
        slipPhotoBase64: map['slipPhotoBase64'] as String?,
        synced: (map['synced'] as int? ?? 0) == 1,
      );
}
