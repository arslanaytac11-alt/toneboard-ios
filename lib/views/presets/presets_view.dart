import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/preset_store.dart';

class PresetsView extends StatelessWidget {
  const PresetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presetler')),
      body: Consumer<PresetStore>(
        builder: (ctx, store, _) {
          if (store.presets.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Henüz preset yok', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text("Pedalboard'dan bir preset kaydedin", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            );
          }
          return ListView.builder(
            itemCount: store.presets.length,
            itemBuilder: (ctx, i) {
              final preset = store.presets[i];
              return ListTile(
                title: Text(preset.name),
                subtitle: Text('${preset.chain.length} pedal'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      final url = 'toneboard://preset/${preset.toBase64()}';
                      Share.share(url, subject: 'ToneBoard Preset: ${preset.name}');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => store.delete(preset.id),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
