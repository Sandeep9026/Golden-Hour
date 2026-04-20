import 'package:flutter/material.dart';

import '../services/alert_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final AlertService _alertService = AlertService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifications = await _alertService.fetchMyNotifications();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Could not load notifications right now.';
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _alertService.markNotificationRead(id: id);
      await _loadNotifications();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark this notification as read.')),
      );
    }
  }

  @override
  void dispose() {
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => item['read_at'] == null).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Center')),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
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
                      'Emergency Alerts Inbox',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('Unread notifications: $unreadCount'),
                    const SizedBox(height: 8),
                    const Text(
                      'This screen represents the product-facing notification center. In later phases, it can be connected to real push delivery.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            else if (_notifications.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No notifications yet.'),
                ),
              )
            else
              ..._notifications.map(
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
                                  item['severity'].toString().toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (item['read_at'] == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB42318).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Color(0xFFB42318),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(item['message'].toString()),
                          const SizedBox(height: 8),
                          Text(
                            'Location: ${item['latitude']}, ${item['longitude']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created: ${item['created_at']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          if (item['read_at'] == null)
                            OutlinedButton(
                              onPressed: () => _markRead((item['id'] as num).toInt()),
                              child: const Text('Mark as read'),
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
