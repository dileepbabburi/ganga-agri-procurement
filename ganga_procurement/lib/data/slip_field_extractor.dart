/// Conservative field suggestions from the plain text returned by local OCR.
/// Every value is only a draft: a worker must check and can edit it.
class SlipDraft {
  const SlipDraft({
    this.farmerName,
    this.mobile,
    this.village,
    this.crop,
    this.bagCount,
    this.rate,
    this.bagWeights = const [],
  });

  final String? farmerName;
  final String? mobile;
  final String? village;
  final String? crop;
  final int? bagCount;
  final double? rate;
  final List<double> bagWeights;

  bool get hasSuggestions =>
      farmerName != null ||
      mobile != null ||
      crop != null ||
      bagCount != null ||
      rate != null ||
      bagWeights.isNotEmpty;
}

/// Extracts only values near recognizable labels or numbered weight rows.
/// This intentionally avoids guessing from unlabeled numbers on the slip.
SlipDraft extractSlipDraft(String text) {
  final lines = text
      .replaceAll('\r', '\n')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String? labelled(Iterable<RegExp> patterns) {
    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        final value = match?.group(1)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  final name = labelled([
    RegExp(
      r"^(?:farmer[’']?s?\s*name|name\s*of\s*farmer|name)\s*[:：-]?\s*(.{2,50})$",
      caseSensitive: false,
    ),
    RegExp(r'^(?:రైతు\s*పేరు)\s*[:：-]?\s*(.{2,50})$'),
  ]);
  final mobileText = labelled([
    RegExp(
      r'^(?:mobile|phone|contact)\s*(?:no\.?|number)?\s*[:：-]?\s*([+()\d\s-]{10,20})$',
      caseSensitive: false,
    ),
  ]);
  final mobileDigits = mobileText?.replaceAll(RegExp(r'\D'), '');
  final mobile =
      mobileDigits != null &&
          mobileDigits.length >= 10 &&
          mobileDigits.length <= 15
      ? mobileDigits
      : null;
  final village = labelled([
    RegExp(r'^(?:village|place)\s*[:：-]?\s*(.{2,50})$', caseSensitive: false),
    RegExp(r'^(?:గ్రామం)\s*[:：-]?\s*(.{2,50})$'),
  ]);

  final bagsText = labelled([
    RegExp(
      r'^(?:total\s*)?(?:no\.?\s*of\s*)?bags\s*[:：-]?\s*(\d{1,3})\b',
      caseSensitive: false,
    ),
    RegExp(r'^(?:సంచులు)\s*[:：-]?\s*(\d{1,3})\b'),
  ]);
  final bagCount = int.tryParse(bagsText ?? '');

  final rateText = labelled([
    RegExp(
      r'^(?:rate\s*(?:/\s*quintal)?|price)\s*(?:per\s*quintal)?\s*[:：-]?\s*(\d{2,6}(?:\.\d{1,2})?)\b',
      caseSensitive: false,
    ),
  ]);
  final rate = double.tryParse(rateText ?? '');

  String? crop;
  for (final line in lines) {
    final found = RegExp(
      r'\b(maize|paddy|jowar|jower|bajra|soyabean|soya\s*bean)\b',
      caseSensitive: false,
    ).firstMatch(line)?.group(1);
    if (found != null) {
      final normalized = found.toLowerCase().replaceAll(' ', '');
      crop = switch (normalized) {
        'maize' => 'Maize',
        'paddy' => 'Paddy',
        'jowar' || 'jower' => 'Jower',
        'bajra' => 'Bajra',
        _ => 'Soyabean',
      };
      break;
    }
  }

  // Form tables typically show serial number followed by a weight. Require
  // consecutive row numbers from 1 so unrelated amounts are not mistaken for
  // bag weights. OCR ambiguity is still shown to the worker for correction.
  final rows = <int, double>{};
  final rowPattern = RegExp(
    r'^\s*(\d{1,3})\s*[.)-]?\s+([0-9]{1,3}(?:[.,][0-9]{1,2})?)\s*(?:kg)?\s*$',
    caseSensitive: false,
  );
  for (final line in lines) {
    final match = rowPattern.firstMatch(line);
    if (match == null) continue;
    final index = int.tryParse(match.group(1)!);
    final weight = double.tryParse(match.group(2)!.replaceAll(',', '.'));
    if (index != null &&
        index >= 1 &&
        index <= 500 &&
        weight != null &&
        weight > 0 &&
        weight < 200) {
      rows[index] = weight;
    }
  }
  final weights = <double>[];
  for (var index = 1; rows.containsKey(index); index++) {
    weights.add(rows[index]!);
  }

  return SlipDraft(
    farmerName: name,
    mobile: mobile,
    village: village,
    crop: crop,
    bagCount: bagCount ?? (weights.isNotEmpty ? weights.length : null),
    rate: rate,
    bagWeights: weights,
  );
}
