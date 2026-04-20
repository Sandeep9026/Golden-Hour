import 'package:flutter/material.dart';

class AboutSafetyScreen extends StatelessWidget {
  const AboutSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About and Safety')),
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
                    'Golden Hour',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Golden Hour is a highway emergency coordination app prototype focused on faster first-response support during the critical minutes after an accident.',
                  ),
                  const SizedBox(height: 12),
                  const Text('Version: 1.0.0-public-readiness'),
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
                children: const [
                  Text(
                    'Safety Disclaimer',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This application is an emergency coordination aid. It should not be treated as a guaranteed substitute for official emergency services, ambulance availability, or professional medical care.',
                  ),
                  SizedBox(height: 10),
                  Text(
                    'In a real emergency, always contact local emergency services immediately and follow official safety guidance.',
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
                children: const [
                  Text(
                    'What the App Uses',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text('• Location data for nearby incident awareness'),
                  Text('• Profile information for responder/driver workflows'),
                  Text('• Incident records for emergency coordination history'),
                  Text('• Notification preferences and device presence for future alert delivery'),
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
                children: const [
                  Text(
                    'Public Release Note',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Before a real public rollout, this app should be paired with a published privacy policy, terms of use, notification delivery service, real-device testing, and a formal release process.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
