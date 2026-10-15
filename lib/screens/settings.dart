import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../main.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';
import 'admin_profile.dart';
import 'plans.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clean(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clean unused data?'),
        content: const Text(
          'All members manually marked Inactive will be permanently deleted. Finance/payment history is preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: warnRed),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Clean Data'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final n = await AppDb.i.cleanInactive();
      if (context.mounted) {
        snack(context, '$n inactive member(s) removed. Finance retained.');
      }
    }
  }

  Future<void> _editGoal(BuildContext context, double current) async {
    var value = current.toStringAsFixed(0);
    final result = await showDialog<double>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Monthly revenue goal'),
        content: TextFormField(
          initialValue: value,
          autofocus: true,
          keyboardType: TextInputType.number,
          onChanged: (v) => value = v,
          decoration: fieldDeco(
            icon: Icons.currency_rupee_rounded,
            hint: 'e.g. 18500',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: ink,
            ),
            onPressed: () => Navigator.pop(d, double.tryParse(value.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      await AppDb.i.setGoal(result);
    }
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

  Widget _tile(
    IconData icon,
    String title,
    String sub, {
    VoidCallback? onTap,
    Color color = orange,
    Widget? trailing,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12.5)),
        trailing:
            trailing ??
            (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const TabHeader('Settings'),
          Expanded(
            child: TopSheet(
              color: pageBg,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  _tile(
                    Icons.account_circle_outlined,
                    'My profile',
                    'View your account, clinic activity and update your password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminProfileScreen(),
                      ),
                    ),
                  ),
                  Live<double>(
                    load: AppDb.i.goal,
                    placeholder: const SizedBox(height: 70),
                    errorBuilder: (c, error, retry) => _tile(
                      Icons.flag_rounded,
                      'Monthly revenue goal',
                      'Unavailable: $error',
                      onTap: retry,
                      color: warnRed,
                      trailing: IconButton(
                        tooltip: 'Retry loading revenue goal',
                        onPressed: retry,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                    builder: (c, goal) => _tile(
                      Icons.flag_rounded,
                      'Monthly revenue goal',
                      '${inr(goal)} - shown on the dashboard progress bar',
                      onTap: () => _editGoal(context, goal),
                    ),
                  ),
                  _tile(
                    Icons.workspace_premium_rounded,
                    'Membership plans',
                    'Set a duration in days, weeks or months and choose the amount',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlansScreen()),
                    ),
                  ),
                  _tile(
                    Icons.storage_rounded,
                    'Cloud database',
                    'Members, payments, notes and check-ins are securely stored on the server.',
                    color: blue,
                  ),
                  _tile(
                    Icons.cleaning_services_rounded,
                    'Clean unused member data',
                    'Delete members marked Inactive. Finance history is kept.',
                    onTap: () => _clean(context),
                  ),
                  _tile(
                    Icons.logout_rounded,
                    'Sign out',
                    'Return to the login screen',
                    color: warnRed,
                    onTap: () => _signOut(context),
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
