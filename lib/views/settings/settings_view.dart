import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/audio_engine.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AudioEngine>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Ses Motoru'),
            subtitle: Text(engine.isRunning ? 'Aktif' : 'Kapalı'),
            trailing: Switch(
              value: engine.isRunning,
              onChanged: (_) => engine.isRunning ? engine.stop() : engine.start(),
            ),
          ),
          const Divider(),
          const ListTile(title: Text('Hakkında'), subtitle: Text('ToneBoard v1.0.0')),
          const ListTile(
            title: Text('Geliştirici'),
            subtitle: Text('ToneBoard'),
          ),
          const ListTile(
            title: Text('Ses Gecikmesi'),
            subtitle: Text('~15ms (Android AudioRecord/AudioTrack)'),
          ),
        ],
      ),
    );
  }
}
