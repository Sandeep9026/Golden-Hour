import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _loading = true;
  bool _saving = false;
  bool _alertsEnabled = true;
  bool _autoCallEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _radiusMeters = 500;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.fetchCurrentSettings();
      if (!mounted) {
        return;
      }
      setState(() {
        _alertsEnabled = settings.alertsEnabled;
        _autoCallEnabled = settings.autoCallEnabled;
        _soundEnabled = settings.soundEnabled;
        _vibrationEnabled = settings.vibrationEnabled;
        _radiusMeters = settings.preferredRadiusMeters.toDouble();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load settings right now.')),
      );
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await _settingsService.saveCurrentSettings(
        alertsEnabled: _alertsEnabled,
        autoCallEnabled: _autoCallEnabled,
        soundEnabled: _soundEnabled,
        vibrationEnabled: _vibrationEnabled,
        preferredRadiusMeters: _radiusMeters.round(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save settings.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Settings'),
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
                    'Alert Preferences',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Configure how the app handles emergency alerts and nearby-incident visibility for your account.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _alertsEnabled,
                  onChanged: (value) => setState(() => _alertsEnabled = value),
                  title: const Text('Enable alerts'),
                  subtitle: const Text('Receive and view nearby accident alerts'),
                ),
                SwitchListTile(
                  value: _autoCallEnabled,
                  onChanged: (value) => setState(() => _autoCallEnabled = value),
                  title: const Text('Enable auto-call flow'),
                  subtitle: const Text('Allow emergency call flow from the SOS action'),
                ),
                SwitchListTile(
                  value: _soundEnabled,
                  onChanged: (value) => setState(() => _soundEnabled = value),
                  title: const Text('Alert sound'),
                  subtitle: const Text('Play an alert sound during emergency notifications'),
                ),
                SwitchListTile(
                  value: _vibrationEnabled,
                  onChanged: (value) => setState(() => _vibrationEnabled = value),
                  title: const Text('Vibration'),
                  subtitle: const Text('Use vibration feedback for alerts'),
                ),
              ],
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
                    'Alert Radius',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('Current radius: ${_radiusMeters.round()} meters'),
                  Slider(
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    value: _radiusMeters,
                    label: '${_radiusMeters.round()} m',
                    onChanged: (value) => setState(() => _radiusMeters = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _saveSettings,
            child: Text(_saving ? 'Saving...' : 'Save Settings'),
          ),
        ],
      ),
    );
  }
}
