import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final SettingsService _settingsService = SettingsService();

  int _page = 0;
  bool _alertsEnabled = true;
  bool _autoCallEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _accepted = false;
  bool _saving = false;

  Future<void> _next() async {
    if (_page < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the safety disclaimer to continue.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _settingsService.saveCurrentSettings(
        alertsEnabled: _alertsEnabled,
        autoCallEnabled: _autoCallEnabled,
        soundEnabled: _soundEnabled,
        vibrationEnabled: _vibrationEnabled,
        preferredRadiusMeters: 500,
        onboardingCompleted: true,
        safetyDisclaimerAccepted: true,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not complete onboarding right now.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _OnboardingPage(
                    title: 'Welcome to Golden Hour',
                    description:
                        'This app helps drivers, responders, and dispatchers coordinate during the first critical minutes after an accident.',
                    icon: Icons.emergency_share_rounded,
                    color: const Color(0xFFB42318),
                  ),
                  _SettingsIntroPage(
                    alertsEnabled: _alertsEnabled,
                    autoCallEnabled: _autoCallEnabled,
                    soundEnabled: _soundEnabled,
                    vibrationEnabled: _vibrationEnabled,
                    onAlertsChanged: (value) => setState(() => _alertsEnabled = value),
                    onAutoCallChanged: (value) => setState(() => _autoCallEnabled = value),
                    onSoundChanged: (value) => setState(() => _soundEnabled = value),
                    onVibrationChanged: (value) => setState(() => _vibrationEnabled = value),
                  ),
                  _DisclaimerPage(
                    accepted: _accepted,
                    onChanged: (value) => setState(() => _accepted = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == index ? const Color(0xFFB42318) : const Color(0xFFD0D5DD),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _next,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_page == 2 ? 'Finish Setup' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _SettingsIntroPage extends StatelessWidget {
  const _SettingsIntroPage({
    required this.alertsEnabled,
    required this.autoCallEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.onAlertsChanged,
    required this.onAutoCallChanged,
    required this.onSoundChanged,
    required this.onVibrationChanged,
  });

  final bool alertsEnabled;
  final bool autoCallEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final ValueChanged<bool> onAlertsChanged;
  final ValueChanged<bool> onAutoCallChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onVibrationChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Safety Preferences',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose how emergency alerts should behave on your device. You can change these later from Safety Settings.',
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: alertsEnabled,
                onChanged: onAlertsChanged,
                title: const Text('Enable nearby alerts'),
              ),
              SwitchListTile(
                value: autoCallEnabled,
                onChanged: onAutoCallChanged,
                title: const Text('Enable auto-call flow'),
              ),
              SwitchListTile(
                value: soundEnabled,
                onChanged: onSoundChanged,
                title: const Text('Alert sound'),
              ),
              SwitchListTile(
                value: vibrationEnabled,
                onChanged: onVibrationChanged,
                title: const Text('Vibration feedback'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisclaimerPage extends StatelessWidget {
  const _DisclaimerPage({
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Safety Disclaimer',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Golden Hour is an emergency coordination aid and academic project. It should not be treated as a guaranteed substitute for official emergency services or professional medical care.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: accepted,
          onChanged: (value) => onChanged(value ?? false),
          title: const Text('I understand and accept this safety disclaimer'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
