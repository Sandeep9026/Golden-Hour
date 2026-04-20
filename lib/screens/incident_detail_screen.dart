import 'package:flutter/material.dart';

import '../services/alert_service.dart';

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({
    super.key,
    required this.incident,
  });

  final Map<String, dynamic> incident;

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final AlertService _alertService = AlertService();
  final TextEditingController _noteController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _updates = const [];

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() => _loading = true);
    try {
      final updates = await _alertService.fetchIncidentUpdates(
        accidentReportId: widget.incident['id'].toString(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _updates = updates;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _addNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _alertService.addIncidentNote(
        accidentReportId: widget.incident['id'].toString(),
        message: note,
      );
      _noteController.clear();
      await _loadUpdates();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident note added.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the note.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final severity = (widget.incident['severity'] as String?) ?? 'medium';
    final status = (widget.incident['status'] as String?) ?? 'reported';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incident ${widget.incident['id'].toString().substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text('Severity: ${severity.toUpperCase()}'),
                  const SizedBox(height: 6),
                  Text('Status: ${status.toUpperCase()}'),
                  const SizedBox(height: 6),
                  Text(
                    'Coordinates: ${widget.incident['latitude']}, ${widget.incident['longitude']}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Responder: ${widget.incident['assigned_responder_name'] ?? 'Not assigned'}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Dispatcher Note',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add an operational note, escalation remark, or case summary...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _saving ? null : _addNote,
                      child: Text(_saving ? 'Saving...' : 'Save Note'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Incident Timeline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_updates.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No timeline entries yet.'),
              ),
            )
          else
            ..._updates.map(
              (update) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (update['update_type'] as String).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(update['message'].toString()),
                        const SizedBox(height: 8),
                        Text(
                          update['created_at'].toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
