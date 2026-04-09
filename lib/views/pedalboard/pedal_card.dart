import 'package:flutter/material.dart';
import '../../models/pedal_definition.dart';
import '../../models/pedal_instance.dart';

class PedalCard extends StatelessWidget {
  final PedalDefinition definition;
  final PedalInstance instance;
  final VoidCallback onBypassToggle;
  final Function(String, double) onParamChanged;
  final VoidCallback onRemove;

  const PedalCard({
    super.key, required this.definition, required this.instance,
    required this.onBypassToggle, required this.onParamChanged, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showEducation(context),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: instance.isBypassed ? Colors.grey.shade900 : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: instance.isBypassed ? Colors.grey.shade700 : Colors.green.shade700),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: instance.isBypassed ? Colors.grey : Colors.green)),
              GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 14, color: Colors.grey)),
            ]),
            const SizedBox(height: 4),
            Text(definition.displayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, maxLines: 2),
            const SizedBox(height: 8),
            ...definition.parameterLabels.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(children: [
                Text(e.value, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                const SizedBox(height: 2),
                _KnobWidget(
                  value: (instance.parameters[e.key] ?? definition.defaultParameters[e.key] ?? 0.0).toDouble(),
                  onChanged: (v) => onParamChanged(e.key, v),
                ),
              ]),
            )),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onBypassToggle,
              child: Container(
                width: 28, height: 14,
                decoration: BoxDecoration(
                  color: instance.isBypassed ? Colors.grey.shade700 : Colors.green.shade700,
                  borderRadius: BorderRadius.circular(7)),
                child: Align(
                  alignment: instance.isBypassed ? Alignment.centerLeft : Alignment.centerRight,
                  child: Padding(padding: const EdgeInsets.all(2),
                    child: Container(width: 10, height: 10,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEducation(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(definition.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(definition.education.summary, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(definition.education.signalPosition, style: const TextStyle(fontSize: 13))),
        ]),
        if (definition.education.notableUsers.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Kullanan sanatçılar', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(definition.education.notableUsers.join(', ')),
        ],
        const SizedBox(height: 16),
      ]),
    ));
  }
}

class _KnobWidget extends StatefulWidget {
  final double value;
  final Function(double) onChanged;
  const _KnobWidget({required this.value, required this.onChanged});

  @override
  State<_KnobWidget> createState() => _KnobWidgetState();
}

class _KnobWidgetState extends State<_KnobWidget> {
  double? _lastY;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _lastY = d.globalPosition.dy,
      onPanUpdate: (d) {
        if (_lastY == null) return;
        final delta = (_lastY! - d.globalPosition.dy) * 0.01;
        _lastY = d.globalPosition.dy;
        widget.onChanged((widget.value + delta).clamp(0.0, 1.0));
      },
      onPanEnd: (_) => _lastY = null,
      child: CustomPaint(painter: _KnobPainter(widget.value), size: const Size(34, 34)),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  _KnobPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    canvas.drawCircle(center, radius, Paint()..color = Colors.grey.shade700..style = PaintingStyle.stroke..strokeWidth = 2);
    final angle = -2.356 + value * 4.712; // -135° to +135°
    final dx = center.dx + (radius - 4) * 0.7 * cos(angle as double);
    final dy = center.dy + (radius - 4) * 0.7 * sin(angle as double);
    canvas.drawLine(center, Offset(dx, dy), Paint()..color = Colors.green..strokeWidth = 2..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_KnobPainter old) => old.value != value;
}

double cos(double angle) => angle == 0 ? 1.0 : _cos(angle);
double sin(double angle) => _sin(angle);
double _cos(double x) { const pi = 3.14159265358979; return _sin(x + pi / 2); }
double _sin(double x) {
  const pi = 3.14159265358979;
  x = x % (2 * pi);
  double result = 0; double term = x; int n = 1;
  while (term.abs() > 1e-10 && n < 20) {
    result += term; n += 2; term *= -x * x / (n * (n - 1));
  }
  return result + term;
}
