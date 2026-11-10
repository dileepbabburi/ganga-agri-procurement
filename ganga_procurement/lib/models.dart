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
    this.approvedByRole = 'worker',
    this.slipPhotoBase64,
    this.synced = false,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerMobile;
  final String crop;
  final List<double> bagWeights;
  final DateTime createdAt;
  final String approvedByRole;
  final String? slipPhotoBase64;
  final bool synced;

  double get grossWeightKg => bagWeights.fold(0, (sum, weight) => sum + weight);
  int get bagCount => bagWeights.length;

  Map<String, Object?> toMap() => {
        'id': id,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'farmerMobile': farmerMobile,
        'crop': crop,
        'bagWeights': jsonEncode(bagWeights),
        'grossWeightKg': grossWeightKg,
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
        approvedByRole: map['approvedByRole'] as String? ?? 'worker',
        slipPhotoBase64: map['slipPhotoBase64'] as String?,
        synced: (map['synced'] as int? ?? 0) == 1,
      );
}
