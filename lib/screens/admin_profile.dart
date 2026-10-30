import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_db.dart';
import '../main.dart';
import '../models/member.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';

class _ProfileData {
  final Map<String, Object?> admin;
  final int members, payments;
  final double total;

  const _ProfileData(this.admin, this.members, this.payments, this.total);
}

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<_ProfileData> _load() async {
    final results = await Future.wait([
      AppDb.i.currentAdmin(),
      AppDb.i.members(),
      AppDb.i.payments(),
    ]);
    final admin = results[0] as Map<String, Object?>;
    final members = results[1] as List<Member>;
    final payments = results[2] as List<Payment>;
    final total = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    return _ProfileData(admin, members.length, payments.length, total);
  }

  Future<void> _editName(BuildContext context, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(current: current),
    );
    if (name == null) return;
    try {
      await AppDb.i.updateAdminName(name);
      if (context.mounted) snack(context, 'Name updated');
    } catch (error) {
      if (context.mounted) snack(context, _errorMessage(error));
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _PasswordDialog(
        onSubmit: (current, next) async {
          try {
            await AppDb.i.changeAdminPassword(current, next);
            return null;
          } catch (error) {
            return _errorMessage(error);
          }
        },
      ),
    );
    if (changed == true && context.mounted) snack(context, 'Password changed');
  }

  Future<void> _signOut(BuildContext context) async {
    await AppDb.i.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Gate()),
        (_) => false,
      );
    }
  }

  String _errorMessage(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  Widget _stat(String value, String label) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tile(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap, {
    Color color = orange,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _subscriptionCard(Map<String, Object?>? subscription, bool isActive) {
    final planType = subscription?['plan_type'] as String?;
    final duration = (subscription?['duration_months'] as num?)?.toInt();
    final start = DateTime.tryParse(
      subscription?['start_date'] as String? ?? '',
    );
    final expiry = DateTime.tryParse(
      subscription?['expiry_date'] as String? ?? '',
    );
    final planName = switch (planType?.toLowerCase()) {
      'monthly' => 'Monthly',
      'quarterly' => 'Quarterly',
      'yearly' => 'Yearly',
      null || '' => 'No plan assigned',
      _ => planType!,
    };
    final durationLabel = duration == null
        ? 'Not available'
        : duration == 1
        ? '1 month'
        : '$duration months';
    final expiryDays = expiry == null
        ? null
        : DateUtils.dateOnly(expiry.toLocal())
              .difference(DateUtils.dateOnly(DateTime.now()))
              .inDays;
    final status = isActive
        ? 'Active'
        : subscription == null
        ? 'No plan assigned'
        : expiryDays != null && expiryDays < 0
        ? 'Expired'
        : 'Inactive';
    final statusColor = isActive ? okGreen : warnRed;
    final remaining = expiryDays == null
        ? 'Not available'
        : expiryDays < 0
        ? 'Expired ${-expiryDays} ${-expiryDays == 1 ? 'day' : 'days'} ago'
        : expiryDays == 0
        ? 'Expires today'
        : '$expiryDays ${expiryDays == 1 ? 'day' : 'days'} remaining';

    Widget detail(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  planName,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Pill(
                status,
                bg: statusColor.withValues(alpha: 0.12),
                fg: statusColor,
              ),
            ],
          ),
          detail('Duration', durationLabel),
          detail(
            'Started',
            start == null
                ? 'Not available'
                : DateFormat('dd MMM yyyy').format(start),
          ),
          detail(
            isActive ? 'Expires' : 'Expiry date',
            expiry == null
                ? 'Not available'
                : DateFormat('dd MMM yyyy').format(expiry),
          ),
          if (expiry != null) detail('Validity', remaining),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const PageHeader(
                'My Profile',
                subtitle: 'Account and clinic activity',
              ),
              Expanded(
                child: TopSheet(
                  color: pageBg,
                  child: Live<_ProfileData>(
                    load: _load,
                    fallbackData: _ProfileData(
                      const {'name': 'Doctor', 'email': '', 'created_at': ''},
                      0,
                      0,
                      0,
                    ),
                    builder: (context, data) {
                      final admin = data.admin;
                      final name = ((admin['name'] as String?) ?? 'Doctor')
                          .trim();
                      final email = (admin['email'] as String?) ?? '';
                      final created = DateTime.tryParse(
                        (admin['created_at'] as String?) ?? '',
                      );
                      final subscriptionValue = admin['subscription'];
                      final subscription = subscriptionValue is Map
                          ? Map<String, Object?>.from(subscriptionValue)
                          : null;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  const Color(0xff14181f),
                                  const Color(0xff1d222b),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: panel,
                                    border: Border.all(color: orange, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: orange.withValues(alpha: 0.2),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    name.isEmpty ? 'C' : name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: orange,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 21,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () =>
                                                _editName(context, name),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.edit_outlined,
                                                color: orange,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (email.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            email,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          const Pill(
                                            'Administrator',
                                            bg: orangeSoft,
                                            fg: Color(0xffb86e00),
                                            icon: Icons.shield_outlined,
                                          ),
                                          if (created != null)
                                            Pill(
                                              'Since ${DateFormat('MMM yyyy').format(created)}',
                                              bg: panel,
                                              fg: Colors.white70,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SectionTitle('Current subscription'),
                          _subscriptionCard(
                            subscription,
                            admin['subscription_active'] == true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _stat('${data.members}', 'Patients'),
                              _stat('${data.payments}', 'Payments'),
                              _stat(inr(data.total), 'Collected'),
                            ],
                          ),
                          const SectionTitle('Clinic data'),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 12,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.cloud_done_outlined, color: okGreen),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Your profile, members and payment records are loaded from the clinic server. '
                                    'Changes are saved to the server database.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12.5,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SectionTitle('Account'),
                          _tile(
                            Icons.lock_reset_rounded,
                            'Change password',
                            'Update your login password',
                            () => _changePassword(context),
                          ),
                          _tile(
                            Icons.logout_rounded,
                            'Sign out',
                            'Return to the login screen',
                            () => _signOut(context),
                            color: warnRed,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  final String current;
  const _NameDialog({required this.current});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController ctl = TextEditingController(
    text: widget.current,
  );
  String? error;

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  void _save() {
    final value = ctl.text.trim();
    if (value.isEmpty) {
      setState(() => error = 'Name cannot be empty.');
      return;
    }
    if (value.length > 120) {
      setState(() => error = 'Name must be 120 characters or fewer.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Name',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const FieldLabel('Full Name', required: true),
          TextField(
            controller: ctl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => error = null),
            decoration: fieldDeco(
              icon: Icons.person_outline,
              hint: 'Your name',
            ),
          ),
          if (error != null) ErrorBanner(error!),
          const SizedBox(height: 18),
          PrimaryButton('Save', icon: Icons.check_rounded, onPressed: _save),
          const SizedBox(height: 10),
          CancelButton(onPressed: () => Navigator.pop(context)),
        ],
      ),
    ),
  );
}

class _PasswordDialog extends StatefulWidget {
  final Future<String?> Function(String currentPassword, String newPassword)
  onSubmit;
  const _PasswordDialog({required this.onSubmit});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (current.text.isEmpty) {
      setState(() => error = 'Enter your current password.');
      return;
    }
    if (next.text.length < 4) {
      setState(() => error = 'New password must be at least 4 characters.');
      return;
    }
    if (next.text != confirm.text) {
      setState(() => error = 'New password and confirmation do not match.');
      return;
    }
    setState(() => busy = true);
    final message = await widget.onSubmit(current.text, next.text);
    if (!mounted) return;
    if (message == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        busy = false;
        error = message;
      });
    }
  }

  Widget _field(TextEditingController controller, String hint) => TextField(
    controller: controller,
    obscureText: true,
    onChanged: (_) => setState(() => error = null),
    decoration: fieldDeco(icon: Icons.lock_outline, hint: hint),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change Password',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const FieldLabel('Current password', required: true),
          _field(current, 'Current password'),
          const FieldLabel('New password', required: true),
          _field(next, 'At least 4 characters'),
          const FieldLabel('Confirm new password', required: true),
          _field(confirm, 'Repeat new password'),
          if (error != null) ErrorBanner(error!),
          const SizedBox(height: 18),
          PrimaryButton(
            'Update Password',
            icon: Icons.check_rounded,
            busy: busy,
            onPressed: _save,
          ),
          const SizedBox(height: 10),
          CancelButton(
            onPressed: () {
              if (!busy) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
