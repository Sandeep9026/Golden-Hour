import 'package:flutter/material.dart';

import '../services/support_service.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final SupportService _supportService = SupportService();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _category = 'feedback';
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _requests = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await _supportService.fetchMyRequests();
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Could not load support requests right now.';
      });
    }
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both subject and message.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _supportService.submitRequest(
        category: _category,
        subject: subject,
        message: message,
      );
      _subjectController.clear();
      _messageController.clear();
      await _loadRequests();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support request submitted.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit support request.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Center')),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help and Feedback',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Use this screen to report bugs, request features, submit safety concerns, or share account-related issues.',
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
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'feedback', child: Text('Feedback')),
                        DropdownMenuItem(value: 'bug', child: Text('Bug report')),
                        DropdownMenuItem(value: 'feature', child: Text('Feature request')),
                        DropdownMenuItem(value: 'safety', child: Text('Safety issue')),
                        DropdownMenuItem(value: 'account', child: Text('Account issue')),
                      ],
                      onChanged: (value) => setState(() => _category = value ?? 'feedback'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: Text(_saving ? 'Submitting...' : 'Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'My Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!),
                ),
              )
            else if (_requests.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No support requests submitted yet.'),
                ),
              )
            else
              ..._requests.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['subject'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(item['status'].toString().toUpperCase()),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Category: ${item['category']}'),
                          const SizedBox(height: 6),
                          Text(item['message'].toString()),
                          const SizedBox(height: 8),
                          Text(
                            item['created_at'].toString(),
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
      ),
    );
  }
}
