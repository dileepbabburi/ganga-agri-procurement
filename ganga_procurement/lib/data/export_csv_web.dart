// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

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
  final blob = html.Blob([utf8.encode('\uFEFF${lines.join('\r\n')}')], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = 'ganga-weighments.csv'
    ..click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
