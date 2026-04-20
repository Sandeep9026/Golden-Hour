import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/alert_service.dart';
import '../services/accident_detector.dart';

class AccidentAlertScreen extends StatelessWidget {
  const AccidentAlertScreen({
    super.key,
    required this.alert,
  });

  final AccidentAlert alert;

  @override
  Widget build(BuildContext context) {
    final severityColor = alert.severity == AccidentSeverity.high
        ? const Color(0xFFB42318)
        : alert.severity == AccidentSeverity.medium
            ? const Color(0xFFD97706)
            : const Color(0xFF0B6E4F);

    return Scaffold(
      appBar: AppBar(title: const Text('Accident Alert')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: severityColor, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          alert.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(alert.description),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Response plan generated. Nearby users can now see this accident and responders can coordinate from the dashboard.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoChip(
                    label: 'Severity',
                    value: alert.severity.label,
                    color: severityColor,
                  ),
                  const SizedBox(height: 10),
                  _InfoChip(
                    label: 'Distance',
                    value: '${alert.distanceMeters.toStringAsFixed(0)} m',
                    color: const Color(0xFF155EEF),
                  ),
                  const SizedBox(height: 10),
                  _InfoChip(
                    label: 'Time',
                    value: DateFormat('dd MMM, hh:mm a').format(alert.createdAt),
                    color: const Color(0xFF6941C6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GPS: ${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 8),
                  Text('Nearest first-aider: ${alert.assignedResponderName ?? 'Pending match'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Return and refresh dashboard'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.map),
            label: const Text('Back to map'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value),
        ],
      ),
    );
  }
}
