// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

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
  final blob = html.Blob([utf8.encode('\uFEFF${lines.join('\r\n')}')], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = 'ganga-weighments.csv'
    ..click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
