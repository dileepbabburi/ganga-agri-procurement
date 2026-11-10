import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'data/export_csv.dart';
import 'data/local_store.dart';
import 'models.dart';

const _green = Color(0xFF145A42);
const _ink = Color(0xFF1F3029);
const _paper = Color(0xFFF5F7F1);
const _lime = Color(0xFFDDF270);
const _uuid = Uuid();
const _cropOptions = ['Maize', 'Paddy', 'Jower', 'Bajra', 'Soyabean'];

void main() => runApp(const GangaApp());

class GangaApp extends StatelessWidget {
  const GangaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'GAG-App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: _paper,
          colorScheme: ColorScheme.fromSeed(seedColor: _green),
          appBarTheme: const AppBarTheme(
            backgroundColor: _paper,
            foregroundColor: _ink,
            centerTitle: false,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8DF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8DF)),
            ),
          ),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.store});

  final LocalStore? store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final LocalStore _store;
  final _picker = ImagePicker();
  final _phoneController = TextEditingController();
  final _newFarmerNameController = TextEditingController();
  final _newFarmerMobileController = TextEditingController();
  final _newFarmerVillageController = TextEditingController();
  final _cropController = TextEditingController();
  final _searchController = TextEditingController();
  final _farmerFormKey = GlobalKey<FormState>();
  final List<TextEditingController> _weightControllers = [TextEditingController()];
  List<Farmer> _farmers = [];
  List<Weighment> _weighments = [];
  Farmer? _farmer;
  String? _selectedCrop;
  Uint8List? _slipBytes;
  String _slipName = '';
  bool _loading = true;
  bool _saving = false;
  bool _addingFarmer = false;
  bool _telugu = false;
  int _tab = 0;

  double get _gross => _weightControllers.fold<double>(
        0,
        (sum, controller) => sum + (double.tryParse(controller.text.trim()) ?? 0),
      );

  List<Farmer> get _farmerMatches {
    final query = _phoneController.text.trim();
    if (query.isEmpty || _farmer != null) return const [];
    return _farmers
        .where((farmer) => farmer.mobile.contains(query))
        .take(5)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? LocalStore();
    _refresh();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _newFarmerNameController.dispose();
    _newFarmerMobileController.dispose();
    _newFarmerVillageController.dispose();
    _cropController.dispose();
    _searchController.dispose();
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    final farmers = await _store.farmers();
    final weighments = await _store.weighments();
    if (!mounted) return;
    setState(() {
      _farmers = farmers;
      _weighments = weighments;
      _loading = false;
    });
  }

  String _label(String english, String telugu) => _telugu ? telugu : english;

  void _findByMobile(String value) {
    setState(() {
      _farmer = _farmers.where((item) => item.mobile == value.trim()).firstOrNull;
    });
  }

  void _addFarmer() {
    _newFarmerNameController.clear();
    _newFarmerMobileController.text = _phoneController.text.trim();
    _newFarmerVillageController.clear();
    setState(() => _addingFarmer = true);
  }

  Future<void> _saveFarmer() async {
    if (!_farmerFormKey.currentState!.validate()) return;
    final digits = _newFarmerMobileController.text.replaceAll(RegExp(r'\D'), '');
    final existing = _farmers.where((item) => item.mobile == digits).firstOrNull;
    final farmer = existing ?? Farmer(
      id: _uuid.v4(),
      name: _newFarmerNameController.text.trim(),
      mobile: digits,
      village: _newFarmerVillageController.text.trim(),
    );
    if (existing == null) await _store.saveFarmer(farmer);
    await _refresh();
    if (!mounted) return;
    _phoneController.text = farmer.mobile;
    setState(() {
      _farmer = farmer;
      _addingFarmer = false;
    });
  }

  Future<void> _pickSlip() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 65,
        maxWidth: 1400,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        _message('That photo is too large. Please take it again.');
        return;
      }
      setState(() {
        _slipBytes = bytes;
        _slipName = file.name;
      });
    } catch (_) {
      _message('Could not open the camera. Check camera permission and try again.');
    }
  }

  Future<void> _saveWeighment() async {
    final farmer = _farmer;
    final crop = _cropController.text.trim();
    final weights = _weightControllers.map((item) => double.tryParse(item.text.trim())).toList();
    if (farmer == null) {
      _message('Find and select a farmer by mobile number first.');
      return;
    }
    if (crop.isEmpty) {
      _message('Enter the crop name.');
      return;
    }
    if (weights.any((weight) => weight == null || weight <= 0)) {
      _message('Enter a bag weight greater than zero in every row.');
      return;
    }
    setState(() => _saving = true);
    final record = Weighment(
      id: _uuid.v4(),
      farmerId: farmer.id,
      farmerName: farmer.name,
      farmerMobile: farmer.mobile,
      crop: crop,
      bagWeights: weights.cast<double>(),
      createdAt: DateTime.now(),
      approvedByRole: 'worker',
      slipPhotoBase64: _slipBytes == null ? null : base64Encode(_slipBytes!),
    );
    try {
      await _store.saveWeighment(record);
      await _refresh();
      if (!mounted) return;
      _resetForm();
      setState(() => _tab = 1);
      _message('Saved on this device and added to the sync queue.');
    } catch (_) {
      _message('This record could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    _phoneController.clear();
    _cropController.clear();
    _selectedCrop = null;
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    _weightControllers
      ..clear()
      ..add(TextEditingController());
    setState(() {
      _farmer = null;
      _slipBytes = null;
      _slipName = '';
    });
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: compact ? 68 : 80,
        titleSpacing: compact ? 12 : 36,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/gag_logo.jpg',
                width: compact ? 38 : 46,
                height: compact ? 38 : 46,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GAG-App',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 11 : 14, fontWeight: FontWeight.w900, letterSpacing: compact ? .2 : .7),
                  ),
                  const Text(
                    'Ganga Agri Genetics',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Color(0xFF6C7A72), fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            if (compact) ...[
              const SizedBox(width: 4),
              PopupMenuButton<bool>(
                tooltip: 'Choose language',
                onSelected: (value) => setState(() => _telugu = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: false, child: Text('English')),
                  PopupMenuItem(value: true, child: Text('తెలుగు')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_telugu ? 'తె' : 'EN', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ]),
                ),
              ),
              const SizedBox(width: 4),
            ] else ...[
              const SizedBox(width: 12),
              _syncPill(),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('EN')),
                  ButtonSegment(value: true, label: Text('తె')),
                ],
                selected: {_telugu},
                onSelectionChanged: (value) => setState(() => _telugu = value.first),
              ),
              const SizedBox(width: 16),
            ],
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: _tab == 0 ? _weighmentPage(compact) : _officePage(compact),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.scale_outlined),
            selectedIcon: const Icon(Icons.scale_rounded),
            label: _telugu ? 'కొత్త తూకం' : 'New weighment',
          ),
          NavigationDestination(
            icon: const Icon(Icons.table_chart_outlined),
            selectedIcon: const Icon(Icons.table_chart_rounded),
            label: _telugu ? 'కార్యాలయం' : 'Office records',
          ),
        ],
      ),
    );
  }

  Widget _syncPill() {
    final pending = _weighments.where((item) => !item.synced).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: const Color(0xFFE8F3E8), borderRadius: BorderRadius.circular(24)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 15, color: _green),
        const SizedBox(width: 6),
        Text(_label('$pending pending', '$pending పెండింగ్'), style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _weighmentPage(bool compact) => ListView(
        padding: EdgeInsets.fromLTRB(compact ? 16 : 36, 18, compact ? 16 : 36, 30),
        children: [
          _hero(compact),
          const SizedBox(height: 22),
          _sectionHeader('01', _label('Farmer', 'రైతు'), _label('Identify by mobile number', 'మొబైల్ నంబర్‌తో గుర్తించండి')),
          const SizedBox(height: 12),
          _farmerPanel(),
          const SizedBox(height: 22),
          _sectionHeader('02', _label('Crop and bags', 'పంట మరియు సంచులు'), _label('Enter the crop and each bag weight', 'పంట పేరు మరియు ప్రతి సంచి బరువును నమోదు చేయండి')),
          const SizedBox(height: 12),
          _bagPanel(compact),
          const SizedBox(height: 22),
          _sectionHeader('03', _label('Weighment slip', 'తూకం స్లిప్'), _label('Take a photo for the record', 'రికార్డు కోసం ఫోటో తీయండి')),
          const SizedBox(height: 12),
          _photoPanel(),
          const SizedBox(height: 20),
          _saveButton(),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _label('Worker submits and approves this weighment', 'కార్మికుడు తూకాన్ని సమర్పించి ఆమోదిస్తారు'),
              style: const TextStyle(color: Color(0xFF627169), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );

  Widget _hero(bool compact) => Container(
        padding: EdgeInsets.all(compact ? 20 : 26),
        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_label('New procurement entry', 'కొత్త కొనుగోలు నమోదు'), style: const TextStyle(color: Color(0xFFD9EBD9), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_label('Quick weighment', 'త్వరిత తూకం'), style: TextStyle(color: Colors.white, fontSize: compact ? 22 : 28, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 8),
              Text(_label('Saved offline on this device', 'ఈ పరికరంలో ఆఫ్‌లైన్‌లో భద్రపరచబడుతుంది'), style: const TextStyle(color: Color(0xFFD9EBD9), fontSize: 12)),
            ]),
          ),
          if (!compact) ...[
            const SizedBox(width: 18),
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.monitor_weight_outlined, size: 42, color: _lime),
            ),
          ],
        ]),
      );

  Widget _sectionHeader(String number, String title, String subtitle) => Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: const Color(0xFFE6EDDF), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(number, style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(subtitle, style: const TextStyle(color: Color(0xFF77847D), fontSize: 11)),
        ])),
      ]);

  Widget _farmerPanel() => _panel(
        child: _addingFarmer
            ? Form(
                key: _farmerFormKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_label('Add farmer', 'రైతును జోడించండి'), style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newFarmerNameController,
                    decoration: InputDecoration(labelText: _label('Farmer name', 'రైతు పేరు')),
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'Enter the farmer name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newFarmerMobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: _label('Mobile number', 'మొబైల్ నంబర్')),
                    validator: (value) {
                      final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                      if (digits.length < 10 || digits.length > 15) return 'Enter a valid mobile number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newFarmerVillageController,
                    decoration: InputDecoration(labelText: _label('Village (optional)', 'గ్రామం (ఐచ్ఛికం)')),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _addingFarmer = false),
                      child: Text(_label('Cancel', 'రద్దు')),
                    ),
                    FilledButton.icon(
                      onPressed: _saveFarmer,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(_label('Save farmer', 'రైతును భద్రపరచండి')),
                    ),
                  ]),
                ]),
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: _findByMobile,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: _label('Search farmer mobile', 'రైతు మొబైల్‌తో వెతకండి'),
                  suffixIcon: _farmer == null
                      ? null
                      : const Icon(Icons.check_circle_rounded, color: _green),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _addFarmer,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(_label('Add', 'జోడించు')),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                minimumSize: const Size(94, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ]),
          if (_farmer != null) ...[
            const SizedBox(height: 12),
            _farmerCard(_farmer!),
          ] else if (_farmerMatches.isNotEmpty) ...[
            const SizedBox(height: 6),
            ..._farmerMatches.map((farmer) => ListTile(
                  dense: true,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEAF1E7), child: Icon(Icons.person_outline, color: _green)),
                  title: Text(farmer.name),
                  subtitle: Text('${farmer.mobile}${farmer.village.isEmpty ? '' : '  ·  ${farmer.village}'}'),
                  onTap: () {
                    _phoneController.text = farmer.mobile;
                    setState(() => _farmer = farmer);
                  },
                )),
          ] else if (_phoneController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_label('No saved farmer found. Add this farmer to continue.', 'రైతు వివరాలు లేవు. కొనసాగడానికి రైతును జోడించండి.'), style: const TextStyle(fontSize: 12, color: Color(0xFF78847D))),
          ],
        ]),
      );

  Widget _farmerCard(Farmer farmer) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: const Color(0xFFEAF2E8), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person_rounded, color: _green)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(farmer.name, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            Text('${farmer.mobile}${farmer.village.isEmpty ? '' : '  ·  ${farmer.village}'}', style: const TextStyle(fontSize: 12, color: Color(0xFF5D6F64))),
          ])),
          IconButton(onPressed: () => setState(() => _farmer = null), icon: const Icon(Icons.close_rounded), tooltip: 'Change farmer'),
        ]),
      );

  Widget _bagPanel(bool compact) => _panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedCrop),
            initialValue: _selectedCrop,
            decoration: InputDecoration(
              labelText: _label('Crop name', 'పంట పేరు'),
              prefixIcon: const Icon(Icons.grain_rounded),
            ),
            items: _cropOptions
                .map((crop) => DropdownMenuItem(value: crop, child: Text(crop)))
                .toList(),
            onChanged: (crop) => setState(() {
              _selectedCrop = crop;
              _cropController.text = crop ?? '';
            }),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Text(_label('Bag weights', 'సంచుల బరువులు'), style: const TextStyle(fontWeight: FontWeight.w800, color: _ink))),
            Text(_label('${_weightControllers.length} bags', '${_weightControllers.length} సంచులు'), style: const TextStyle(fontSize: 12, color: Color(0xFF738078))),
          ]),
          const SizedBox(height: 9),
          ...List.generate(_weightControllers.length, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFF0F3EC), borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: _green)),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: _weightControllers[index],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: _label('Enter bag weight', 'సంచి బరువు నమోదు చేయండి'),
                        suffixText: 'kg',
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_weightControllers.length > 1)
                    IconButton(
                      onPressed: () => setState(() {
                        _weightControllers.removeAt(index).dispose();
                      }),
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF9A5A4D)),
                      tooltip: 'Remove bag',
                    ),
                ]),
              )),
          OutlinedButton.icon(
            onPressed: () => setState(() => _weightControllers.add(TextEditingController())),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: Text(_label('Add another bag', 'మరొక సంచిని జోడించండి')),
            style: OutlinedButton.styleFrom(foregroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: BoxDecoration(color: const Color(0xFFF0F5E2), borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              const Icon(Icons.functions_rounded, color: _green),
              const SizedBox(width: 10),
              Expanded(child: Text(_label('Gross weight', 'మొత్తం బరువు'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink))),
              Text('${_gross.toStringAsFixed(2)} kg', style: TextStyle(fontSize: compact ? 19 : 22, fontWeight: FontWeight.w900, color: _green)),
            ]),
          ),
        ]),
      );

  Widget _photoPanel() => _panel(
        child: Row(children: [
          Container(
            width: 62,
            height: 62,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xFFF0F3EC), borderRadius: BorderRadius.circular(14)),
            child: _slipBytes == null
                ? const Icon(Icons.receipt_long_rounded, size: 27, color: _green)
                : Image.memory(_slipBytes!, fit: BoxFit.cover),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_slipBytes == null ? _label('Slip photo optional', 'స్లిప్ ఫోటో ఐచ్ఛికం') : _slipName, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 3),
            Text(_label('Stored with the offline weighment', 'ఆఫ్‌లైన్ తూకంతో భద్రపరచబడుతుంది'), style: const TextStyle(fontSize: 11, color: Color(0xFF758078))),
          ])),
          OutlinedButton.icon(
            onPressed: _pickSlip,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(_label('Take photo', 'ఫోటో తీయండి')),
            style: OutlinedButton.styleFrom(foregroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      );

  Widget _saveButton() => FilledButton.icon(
        onPressed: _saving ? null : _saveWeighment,
        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded),
        label: Text(_saving ? _label('Saving…', 'భద్రపరుస్తోంది…') : _label('Save weighment', 'తూకాన్ని భద్రపరచండి')),
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );

  Widget _officePage(bool compact) {
    final query = _searchController.text.trim().toLowerCase();
    final records = _weighments.where((item) =>
        query.isEmpty || item.farmerName.toLowerCase().contains(query) || item.farmerMobile.contains(query)).toList();
    final totalKg = _weighments.fold<double>(0, (sum, item) => sum + item.grossWeightKg);
    final pending = _weighments.where((item) => !item.synced).length;
    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 36, 22, compact ? 16 : 36, 30),
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_label('Office records', 'కార్యాలయ రికార్డులు'), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _ink)),
            const SizedBox(height: 5),
            Text(_label('Records stored on this device', 'ఈ పరికరంలో భద్రపరిచిన రికార్డులు'), style: const TextStyle(color: Color(0xFF748078), fontSize: 12)),
          ])),
          OutlinedButton.icon(
            onPressed: _weighments.isEmpty ? null : () => exportWeighmentsCsv(_weighments),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(_label('Export CSV', 'CSV ఎగుమతి')),
            style: OutlinedButton.styleFrom(foregroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _metric(_label('Weighments', 'తూకాలు'), '${_weighments.length}', Icons.receipt_long_outlined),
          _metric(_label('Gross kg', 'మొత్తం కిలోలు'), totalKg.toStringAsFixed(2), Icons.scale_outlined),
          _metric(_label('Pending sync', 'సింక్ పెండింగ్'), '$pending', Icons.cloud_upload_outlined),
        ]),
        const SizedBox(height: 17),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: _label('Search farmer name or mobile', 'రైతు పేరు లేదా మొబైల్ వెతకండి'),
          ),
        ),
        const SizedBox(height: 14),
        if (records.isEmpty)
          _panel(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              const Icon(Icons.inventory_2_outlined, size: 38, color: Color(0xFF8C998F)),
              const SizedBox(height: 8),
              Text(_weighments.isEmpty ? _label('No weighments saved yet', 'ఇంకా తూకాలు భద్రపరచలేదు') : _label('No matching records', 'సరిపోలిన రికార్డులు లేవు'), style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
            ]),
          ))
        else
          ...records.map(_recordCard),
        const SizedBox(height: 13),
        Text(
          _label('Commercial deductions and payment calculations are not included.', 'వాణిజ్య కోతలు మరియు చెల్లింపు లెక్కలు ఇందులో లేవు.'),
          style: const TextStyle(fontSize: 11, color: Color(0xFF758078)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon) => Container(
        constraints: const BoxConstraints(minWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8DF)), borderRadius: BorderRadius.circular(15)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: _green, size: 20),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF77847D))),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
          ]),
        ]),
      );

  Widget _recordCard(Weighment item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _panel(
          child: Row(children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(color: const Color(0xFFF0F5E2), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.scale_rounded, color: _green),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.farmerName, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
              Text('${item.farmerMobile}  ·  ${item.crop}  ·  ${_label('${item.bagCount} bags', '${item.bagCount} సంచులు')}', style: const TextStyle(fontSize: 11, color: Color(0xFF738078))),
              const SizedBox(height: 4),
              Text(_formatDate(item.createdAt), style: const TextStyle(fontSize: 10, color: Color(0xFF89948D))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${item.grossWeightKg.toStringAsFixed(2)} kg', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _green)),
              const SizedBox(height: 5),
              Text('${item.approvedByRole == 'worker' ? _label('Worker approved', 'కార్మికుడు ఆమోదించారు') : item.approvedByRole}  ·  ${item.synced ? _label('Synced', 'సింక్ అయింది') : _label('Pending sync', 'సింక్ పెండింగ్')}', style: TextStyle(fontSize: 10, color: item.synced ? _green : const Color(0xFF9A6A22), fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      );

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}  ${two(local.hour)}:${two(local.minute)}';
  }

  Widget _panel({required Widget child}) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE3E8E0)), borderRadius: BorderRadius.circular(18)),
        child: child,
      );
}
