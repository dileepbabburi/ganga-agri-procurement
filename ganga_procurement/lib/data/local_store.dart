import 'local_store_mobile.dart'
    if (dart.library.html) 'local_store_web.dart' as implementation;
import '../models.dart';

abstract class LocalStore {
  factory LocalStore() => implementation.createLocalStore();

  Future<List<Farmer>> farmers();
  Future<void> saveFarmer(Farmer farmer);
  Future<List<Weighment>> weighments();
  Future<void> saveWeighment(Weighment weighment);
}
