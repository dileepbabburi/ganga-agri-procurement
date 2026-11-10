import 'export_csv_mobile.dart'
    if (dart.library.html) 'export_csv_web.dart' as implementation;
import '../models.dart';

Future<void> exportWeighmentsCsv(List<Weighment> weighments) =>
    implementation.exportWeighmentsCsv(weighments);
