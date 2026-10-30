import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/common.dart';

class InactiveAccountScreen extends StatelessWidget {
  const InactiveAccountScreen({super.key});

  static const _providerName = 'RewantechSolutions';
  static const _contactNumber = '918545098444';
  static const _contactNumbers = [
    '+91 8009768896',
    '+91 9369620030',
    '+91 8545098444',
  ];

  Future<void> _contactProvider(BuildContext context) async {
    final uri = Uri.https('wa.me', '/$_contactNumber', {
      'text': 'Hello, my PhysioCare clinic account is inactive. Please help.',
    });
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        snack(context, 'Could not open WhatsApp or a browser on this device.');
      }
    } on PlatformException {
      if (context.mounted) {
        snack(context, 'Could not open WhatsApp or a browser on this device.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Account inactive'),
      leading: IconButton(
        tooltip: 'Back to login',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: NightBackground(
      child: SafeArea(
        top: false,
        child: TopSheet(
          color: pageBg,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: redSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_outlined,
                  color: warnRed,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your account is inactive',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You cannot sign in while your account is inactive. Contact '
                'the service provider to restore access.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: lineGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service provider',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      _providerName,
                      style: TextStyle(color: ink, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Contact numbers',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    for (final number in _contactNumbers)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          number,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _contactProvider(context),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Contact service provider'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
