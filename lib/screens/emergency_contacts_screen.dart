import 'package:flutter/material.dart';

import '../services/emergency_contact_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyContactService _contactService = EmergencyContactService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _notifyOnSos = true;
  String? _error;
  List<Map<String, dynamic>> _contacts = const [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final contacts = await _contactService.fetchContacts();
      if (!mounted) {
        return;
      }
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Could not load emergency contacts right now.';
      });
    }
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final relation = _relationController.text.trim();

    if (name.isEmpty || phone.isEmpty || relation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all contact fields.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _contactService.addContact(
        contactName: name,
        phone: phone,
        relation: relation,
        notifyOnSos: _notifyOnSos,
      );
      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();
      _notifyOnSos = true;
      await _loadContacts();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contact added.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add contact.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteContact(int id) async {
    try {
      await _contactService.deleteContact(id: id);
      await _loadContacts();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove contact.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: RefreshIndicator(
        onRefresh: _loadContacts,
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
                      'Trusted Contacts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add family members, friends, or colleagues who should be associated with your emergency profile.',
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
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _relationController,
                      decoration: const InputDecoration(
                        labelText: 'Relation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mark for SOS notification'),
                      subtitle: const Text('Use this contact in future notification workflows'),
                      value: _notifyOnSos,
                      onChanged: (value) => setState(() => _notifyOnSos = value),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _saving ? null : _addContact,
                        child: Text(_saving ? 'Saving...' : 'Add Contact'),
                      ),
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
            else if (_contacts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No emergency contacts added yet.'),
                ),
              )
            else
              ..._contacts.map(
                (contact) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        contact['contact_name'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact['phone'].toString()),
                            const SizedBox(height: 4),
                            Text('Relation: ${contact['relation']}'),
                            const SizedBox(height: 4),
                            Text(
                              contact['notify_on_sos'] == true
                                  ? 'Eligible for SOS notifications'
                                  : 'Reference contact only',
                            ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => _deleteContact((contact['id'] as num).toInt()),
                        icon: const Icon(Icons.delete_outline_rounded),
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
