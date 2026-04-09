import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio/audio_engine.dart';
import 'services/pedal_registry.dart';
import 'services/preset_store.dart';
import 'services/freemium_gate.dart';
import 'views/pedalboard/pedalboard_view.dart';
import 'views/shop/shop_view.dart';
import 'views/presets/presets_view.dart';
import 'views/settings/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PedalRegistry.shared.init();
  final presetStore = PresetStore();
  await presetStore.load();
  runApp(ToneBoardApp(presetStore: presetStore));
}

class ToneBoardApp extends StatelessWidget {
  final PresetStore presetStore;
  const ToneBoardApp({super.key, required this.presetStore});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AudioEngine()),
        ChangeNotifierProvider(create: (_) => FreemiumGate()),
        ChangeNotifierProvider.value(value: presetStore),
      ],
      child: MaterialApp(
        title: 'ToneBoard',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1DB954),
            brightness: Brightness.dark,
          ),
        ),
        home: const MainScaffold(),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static const _tabs = [
    PedalboardView(),
    ShopView(),
    PresetsView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.tune), label: 'Pedalboard'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Presetler'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
