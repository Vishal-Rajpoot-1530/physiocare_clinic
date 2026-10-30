import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/app_db.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';
import 'auth.dart';
import 'shell.dart';

class SubscriptionExpiredScreen extends StatefulWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  State<SubscriptionExpiredScreen> createState() =>
      _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends State<SubscriptionExpiredScreen> {
  static const _contactNumber = '918545098444';
  static const _contactNumbers = [
    '+91 8009768896',
    '+91 9369620030',
    '+91 8545098444',
  ];
  static const _plans = [
    (title: 'Monthly', duration: '1 month', price: 150),
    (title: 'Quarterly', duration: '3 months', price: 300),
    (title: 'Yearly', duration: '12 months', price: 1000),
  ];

  bool checking = false;
  bool returningToLogin = false;

  Future<void> _returnToLogin() async {
    if (returningToLogin) return;
    setState(() => returningToLogin = true);
    try {
      await AppDb.i.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      snack(context, 'Could not return to login: $error');
      setState(() => returningToLogin = false);
    }
  }

  Future<void> _requestPlan(
    BuildContext context,
    Map<String, Object?> admin,
    ({String title, String duration, int price}) plan,
  ) async {
    final message = [
      'Subscription renewal request',
      'Admin ID: ${admin['id'] ?? 'Not provided'}',
      'Admin name: ${(admin['name'] as String? ?? '').trim()}',
      'Admin email: ${(admin['email'] as String? ?? '').trim()}',
      'Requested plan: ${plan.title} (${plan.duration})',
    ].join('\n');
    final uri = Uri.https('wa.me', '/$_contactNumber', {'text': message});
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

  Future<void> _checkSubscription() async {
    if (checking) return;
    setState(() => checking = true);
    try {
      final admin = await AppDb.i.currentAdmin();
      if (!mounted) return;
      if (admin['subscription_active'] == true) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
      } else {
        snack(
          context,
          'The plan is still expired. Please contact us to renew.',
        );
      }
    } catch (error) {
      if (mounted) snack(context, 'Could not check subscription: $error');
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  Widget _planCard(
    BuildContext context,
    Map<String, Object?> admin,
    ({String title, String duration, int price}) plan,
  ) {
    final featured = plan.title == 'Yearly';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: featured ? orange.withValues(alpha: 0.45) : lineGrey,
        ),
        boxShadow: [
          BoxShadow(
            color: featured
                ? orange.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.025),
            blurRadius: featured ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: orangeSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  featured
                      ? Icons.workspace_premium_rounded
                      : Icons.calendar_month_rounded,
                  color: orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan.title,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (featured) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: orangeSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(
                                color: ink,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.duration,
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                inr(plan.price),
                style: const TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: featured ? orange : orangeSoft,
                foregroundColor: featured ? Colors.white : ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _requestPlan(context, admin, plan),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text(
                'Renew via WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(Map<String, Object?> admin) {
    final subscriptionValue = admin['subscription'];
    final subscription = subscriptionValue is Map
        ? Map<String, Object?>.from(subscriptionValue)
        : null;
    final hasPreviousSubscription = subscription != null;
    final plan = (subscription?['plan_type'] as String? ?? 'unknown')
        .toLowerCase();
    final duration = (subscription?['duration_months'] as num?)?.toInt();
    final expiry = DateTime.tryParse(
      subscription?['expiry_date'] as String? ?? '',
    );
    final planTitle = switch (plan) {
      'monthly' => 'Monthly',
      'quarterly' => 'Quarterly',
      'yearly' => 'Yearly',
      'unknown' => 'No active plan',
      _ => plan,
    };
    final durationLabel = duration == null
        ? 'Not available'
        : duration == 1
        ? '1 month'
        : '$duration months';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [orange, Color.lerp(orange, ink, 0.22)!],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: orange.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -32,
                top: -46,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.lock_clock_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                hasPreviousSubscription
                                    ? 'PLAN EXPIRED'
                                    : 'PLAN REQUIRED',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      hasPreviousSubscription
                          ? 'Your subscription has ended'
                          : 'Choose a plan to get started',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Renew your PhysioCare clinic plan to restore access '
                      'to your management workspace.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: lineGrey),
            boxShadow: [
              BoxShadow(
                color: ink.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Subscription details',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: redSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: warnRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _detailRow(Icons.workspace_premium_outlined, 'Plan', planTitle),
              const SizedBox(height: 13),
              _detailRow(Icons.timelapse_rounded, 'Duration', durationLabel),
              const SizedBox(height: 13),
              _detailRow(
                Icons.event_busy_rounded,
                hasPreviousSubscription ? 'Expired on' : 'Plan expiry',
                expiry == null
                    ? 'Not available'
                    : DateFormat('dd MMM yyyy').format(expiry),
                valueColor: warnRed,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Choose your plan',
          style: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Select an option below to request a secure renewal.',
          style: TextStyle(color: muted, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 14),
        for (final plan in _plans) _planCard(context, admin, plan),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: blueSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: blue.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.support_agent_rounded, color: blue),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Need a hand?',
                      style: TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'RewantechSolutions',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                'Our team can help you choose the right plan.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final number in _contactNumbers)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              side: BorderSide(color: orange.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: checking ? null : _checkSubscription,
            icon: checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(
              checking
                  ? 'Checking subscription...'
                  : 'I have renewed — check again',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: returningToLogin ? null : _returnToLogin,
          icon: returningToLogin
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout_rounded, size: 18),
          label: Text(
            returningToLogin ? 'Returning to login...' : 'Back to login',
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = ink,
  }) => Row(
    children: [
      Icon(icon, size: 18, color: muted),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label, style: const TextStyle(color: muted, fontSize: 13)),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: NightBackground(
        child: SafeArea(
          child: TopSheet(
            color: pageBg,
            child: Live<Map<String, Object?>>(
              load: AppDb.i.currentAdmin,
              errorBuilder: (context, error, retry) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: warnRed,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load subscription details: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ink),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              builder: (context, admin) => _content(admin),
            ),
          ),
        ),
      ),
    ),
  );
}
