import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganga_procurement/data/local_store.dart';
import 'package:ganga_procurement/main.dart';
import 'package:ganga_procurement/models.dart';

class _MemoryStore implements LocalStore {
  final List<Farmer> savedFarmers = [];
  final List<Weighment> savedWeighments = [];

  @override
  Future<List<Farmer>> farmers() async => List.of(savedFarmers);

  @override
  Future<void> saveFarmer(Farmer farmer) async => savedFarmers.add(farmer);

  @override
  Future<List<Weighment>> weighments() async => List.of(savedWeighments);

  @override
  Future<void> saveWeighment(Weighment weighment) async => savedWeighments.add(weighment);
}

void main() {
  Future<void> pumpAtPhoneWidth(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: HomePage(store: _MemoryStore())));
    await tester.pumpAndSettle();
  }

  testWidgets('fits a narrow phone and shows only the selected language', (tester) async {
    await pumpAtPhoneWidth(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Farmer'), findsOneWidget);
    expect(find.text('రైతు'), findsNothing);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('తెలుగు').last);
    await tester.pumpAndSettle();

    expect(find.text('పంట పేరు'), findsOneWidget);
    expect(find.text('Crop name'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers the five requested crops and saves the selected name', (tester) async {
    await pumpAtPhoneWidth(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    for (final crop in ['Maize', 'Paddy', 'Jower', 'Bajra', 'Soyabean']) {
      expect(find.text(crop), findsOneWidget);
    }

    await tester.tap(find.text('Jower'));
    await tester.pumpAndSettle();
    expect(find.text('Jower'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calculates payment for gross weight, bag count, and AR', (tester) async {
    await pumpAtPhoneWidth(tester);

    final cropDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(cropDropdown);
    await tester.tap(cropDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maize').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'crop selection');
    final grossMode = find.byKey(const ValueKey('gross-weight-mode'));
    await tester.ensureVisible(grossMode);
    await tester.tap(grossMode);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'weight mode selection');

    await tester.ensureVisible(find.byKey(const ValueKey('total-bags-input')));
    await tester.enterText(find.byKey(const ValueKey('total-bags-input')), '56');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'bag count entry');
    await tester.ensureVisible(find.byKey(const ValueKey('gross-weight-input')));
    await tester.enterText(find.byKey(const ValueKey('gross-weight-input')), '3270');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'gross weight entry');
    await tester.ensureVisible(find.byKey(const ValueKey('rate-per-quintal-input')));
    await tester.enterText(find.byKey(const ValueKey('rate-per-quintal-input')), '2500');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'rate entry');

    await tester.ensureVisible(find.text('Final payable to farmer'));
    expect(find.text('₹78,183.00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final hrChoice = find.byKey(const ValueKey('hr-receipt-choice'));
    await tester.ensureVisible(hrChoice);
    await tester.tap(hrChoice);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Final payable to farmer'));
    expect(find.text('₹77,623.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
