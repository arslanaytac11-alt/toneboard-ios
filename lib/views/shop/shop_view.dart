import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pedal_definition.dart';
import '../../models/pedal_instance.dart';
import '../../services/pedal_registry.dart';
import '../../services/freemium_gate.dart';
import '../pedalboard/pedalboard_view.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  PedalCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final defs = PedalRegistry.shared.allDefinitions(category: _selectedCategory);

    return Scaffold(
      appBar: AppBar(title: const Text('Pedal Shop')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(null, 'Tümü'),
                ...PedalCategory.values.map((c) => _chip(c, c.name[0].toUpperCase() + c.name.substring(1))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: defs.length,
              itemBuilder: (ctx, i) => _ShopPedalCard(definition: defs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(PedalCategory? cat, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: _selectedCategory == cat,
      onSelected: (_) => setState(() => _selectedCategory = cat),
    ),
  );
}

class _ShopPedalCard extends StatefulWidget {
  final PedalDefinition definition;
  const _ShopPedalCard({required this.definition});

  @override
  State<_ShopPedalCard> createState() => _ShopPedalCardState();
}

class _ShopPedalCardState extends State<_ShopPedalCard> {
  bool _demoRunning = false;

  @override
  Widget build(BuildContext context) {
    final gate = context.watch<FreemiumGate>();
    final owned = gate.isPedalAccessible(widget.definition.pedalID);

    return ListTile(
      title: Text(widget.definition.displayName),
      subtitle: Text(widget.definition.education.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: widget.definition.isPremium
          ? (owned && !_demoRunning
              ? const Icon(Icons.check_circle, color: Colors.green)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!owned) ...[
                    TextButton(onPressed: _startDemo, child: Text(_demoRunning ? 'Demo' : 'Dene')),
                    const SizedBox(width: 4),
                  ],
                  ElevatedButton(
                    onPressed: () => _addToBoard(context),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    child: const Text('Ekle'),
                  ),
                ]))
          : ElevatedButton(
              onPressed: () => _addToBoard(context),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: const Text('Ekle'),
            ),
    );
  }

  void _startDemo() {
    setState(() => _demoRunning = true);
    context.read<FreemiumGate>().startDemo(widget.definition.pedalID);
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) setState(() => _demoRunning = false);
    });
  }

  void _addToBoard(BuildContext context) {
    final gate = context.read<FreemiumGate>();
    if (widget.definition.isPremium && !gate.isPedalAccessible(widget.definition.pedalID)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu pedal için satın al veya 60s dene')));
      return;
    }
    final instance = PedalInstance(
      pedalID: widget.definition.pedalID,
      parameters: Map.from(widget.definition.defaultParameters),
    );
    // Pedalboard'a ekle — GlobalKey ile erişim yerine Navigator pop + callback kullanıyoruz
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.definition.displayName} Pedalboard\'a eklendi'),
        action: SnackBarAction(label: 'Geri al', onPressed: () {})));
  }
}
