import 'package:flutter/material.dart';

import 'home_screen.dart';
import '../services/profile_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  String _role = 'driver';
  bool _trained = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please enter your name and phone number.')),
        );
        return;
      }

      final profileService = ProfileService();
      await profileService.upsertCurrentProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        isTrained: _role == 'first_aider' ? _trained : false,
        vehicleNumber: _vehicleController.text.trim(),
      );
      final profile = await profileService.fetchCurrentProfile();
      if (!mounted) {
        return;
      }
      if (profile == null) {
        throw StateError('Profile not found after save');
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
        (route) => false,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile could not be saved. Check your Supabase configuration.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7D8CE), Color(0xFFF7F1E8), Color(0xFFDDF0EA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8E7E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Step 2 of 2',
                            style: TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Profile Setup',
                          style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Complete your details so the app can identify you as a driver, responder, or dispatcher.',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F2EA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE7D7CC)),
                          ),
                          child: const Text(
                            'Choose a realistic role for your demo. A trained first-aider account is useful for showing responder assignment.',
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _role,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'driver', child: Text('Driver')),
                            DropdownMenuItem(
                              value: 'first_aider',
                              child: Text('Trained First-Aider'),
                            ),
                            DropdownMenuItem(
                              value: 'dispatcher',
                              child: Text('Dispatcher'),
                            ),
                          ],
                          onChanged: (value) => setState(() => _role = value ?? 'driver'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _vehicleController,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle Number (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_role == 'first_aider') ...[
                          const SizedBox(height: 10),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Training Completed'),
                            subtitle: const Text('CPR / first-aid trained responder'),
                            value: _trained,
                            onChanged: (value) => setState(() => _trained = value),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _saveProfile,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFB42318),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
