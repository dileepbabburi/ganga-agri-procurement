import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../models.dart';

Future<void> exportWeighmentsCsv(List<Weighment> weighments) async {
  const header = 'Record ID,Date,Farmer,Mobile,Crop,Bags,Gross weight (kg),Approved by,Sync status';
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
          item.grossWeightKg.toStringAsFixed(2),
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
