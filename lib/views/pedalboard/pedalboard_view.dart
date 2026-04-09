import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/audio_engine.dart';
import '../../models/pedal_instance.dart';
import '../../models/preset.dart';
import '../../services/pedal_registry.dart';
import '../../services/preset_store.dart';
import '../../services/freemium_gate.dart';
import 'pedal_card.dart';

class PedalboardView extends StatefulWidget {
  const PedalboardView({super.key});

  @override
  State<PedalboardView> createState() => _PedalboardViewState();
}

class _PedalboardViewState extends State<PedalboardView> {
  List<PedalInstance> _chain = [];
  bool _engineRunning = false;
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _toggleEngine() async {
    final engine = context.read<AudioEngine>();
    if (_engineRunning) {
      await engine.stop();
    } else {
      await engine.start();
      await engine.setChain(_chain.map((e) => e.pedalID).toList());
    }
    setState(() => _engineRunning = !_engineRunning);
  }

  void _savePreset() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Preset Adı'),
      content: TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Preset adı girin')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        TextButton(onPressed: () {
          if (_nameCtrl.text.isNotEmpty) {
            final preset = Preset(name: _nameCtrl.text, chain: List.from(_chain));
            context.read<PresetStore>().save(preset);
            _nameCtrl.clear();
          }
          Navigator.pop(context);
        }, child: const Text('Kaydet')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedalboard'),
        actions: [
          IconButton(
            icon: Icon(_engineRunning ? Icons.stop_circle : Icons.play_circle,
              color: _engineRunning ? Colors.red : Colors.green),
            onPressed: _toggleEngine,
            tooltip: _engineRunning ? 'Durdur' : 'Başlat',
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _chain.isEmpty ? null : _savePreset),
        ],
      ),
      body: _chain.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.queue_music, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Shop\'tan pedal ekleyin', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(_engineRunning ? '● Ses aktif' : '○ Ses kapalı',
                  style: TextStyle(color: _engineRunning ? Colors.green : Colors.grey, fontSize: 12)),
              ]),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Icon(Icons.circle, size: 10, color: _engineRunning ? Colors.green : Colors.grey),
                    const SizedBox(width: 6),
                    Text(_engineRunning ? 'Ses aktif' : 'Ses kapalı',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    itemCount: _chain.length,
                    onReorder: (from, to) {
                      setState(() {
                        final item = _chain.removeAt(from);
                        _chain.insert(to > from ? to - 1 : to, item);
                      });
                      context.read<AudioEngine>().setChain(_chain.map((e) => e.pedalID).toList());
                    },
                    itemBuilder: (ctx, i) {
                      final instance = _chain[i];
                      final def = PedalRegistry.shared.definition(instance.pedalID);
                      if (def == null) return const SizedBox.shrink(key: ValueKey('unknown'));
                      return Padding(
                        key: ValueKey(instance.id),
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(children: [
                          PedalCard(
                            definition: def,
                            instance: instance,
                            onBypassToggle: () {
                              setState(() => instance.isBypassed = !instance.isBypassed);
                              context.read<AudioEngine>().setBypass(instance.pedalID, instance.isBypassed);
                            },
                            onParamChanged: (key, val) {
                              setState(() => instance.parameters[key] = val);
                              context.read<AudioEngine>().setParameter(instance.pedalID, key, val);
                            },
                            onRemove: () {
                              setState(() => _chain.removeAt(i));
                              context.read<AudioEngine>().setChain(_chain.map((e) => e.pedalID).toList());
                            },
                          ),
                          if (i < _chain.length - 1)
                            Container(width: 20, height: 6, decoration: BoxDecoration(
                              color: Colors.brown.shade400, borderRadius: BorderRadius.circular(3))),
                        ]),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void addPedal(PedalInstance instance) {
    final gate = context.read<FreemiumGate>();
    if (!gate.canAddPedal(_chain.length)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ücretsiz kullanımda maksimum 3 pedal eklenebilir')));
      return;
    }
    setState(() => _chain.add(instance));
    context.read<AudioEngine>().setChain(_chain.map((e) => e.pedalID).toList());
  }
}
