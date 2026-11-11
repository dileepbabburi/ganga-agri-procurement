import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../models.dart';

Future<void> exportWeighmentsCsv(List<Weighment> weighments) async {
  const header = 'Record ID,Date,Farmer,Mobile,Crop,Bags,Weight entry mode,Gross weight (kg),Less gunny (kg),Kadtha (kg),Good seed (kg),Rate per quintal,Gross payment,Interest rate (%),Interest deducted,Receipt type,Receipt per bag,Receipt total,Final payable,Approved by,Sync status';
  String cell(String value) => '"${value.replaceAll('"', '""')}"';
  final lines = [
    header,
    ...weighments.map((item) => [
          item.id,
          item.createdAt.toLocal().toIso8601String(),
          item.farmerName,
          item.farmerMobile,
          item.crop,
          item.bagCount.toString(),
          item.weightEntryMode,
          item.grossWeightKg.toStringAsFixed(2),
          item.gunnyDeductionKg.toStringAsFixed(2),
          item.kadthaKg.toStringAsFixed(2),
          item.goodSeedWeightKg.toStringAsFixed(2),
          item.ratePerQuintal.toStringAsFixed(2),
          item.grossPayment.toStringAsFixed(2),
          item.interestRatePercent.toStringAsFixed(2),
          item.interestAmount.toStringAsFixed(2),
          item.receiptType,
          item.receiptPerBag.toStringAsFixed(2),
          item.receiptTotal.toStringAsFixed(2),
          item.finalPayable.toStringAsFixed(2),
          item.approvedByRole,
          item.synced ? 'Synced' : 'Pending',
        ].map(cell).join(',')),
  ];
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(utf8.encode('\uFEFF${lines.join('\r\n')}'), mimeType: 'text/csv')],
    fileNameOverrides: const ['ganga-weighments.csv'],
    subject: 'Ganga Agri Genetics weighments',
  ));
}
