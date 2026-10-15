import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/app_db.dart';
import '../models/member.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';
import '../widgets/renew_dialog.dart';
import 'add_member.dart';

class _P {
  final Member? m;
  final List<Payment> pays;
  final int total, streak;
  const _P(this.m, this.pays, this.total, this.streak);
}

class ProfileScreen extends StatelessWidget {
  final int id;
  const ProfileScreen({super.key, required this.id});

  Future<_P> _load() async {
    final m = await AppDb.i.member(id);
    if (m == null) return const _P(null, [], 0, 0);
    final pays = await AppDb.i.paymentsFor(id);
    final cs = await AppDb.i.checkinStats(id);
    return _P(m, pays, cs.total, cs.streak);
  }

  // ---------------------------------------------------------- actions
  Future<void> _renew(BuildContext context, Member m) async {
    final plans = await AppDb.i.plans();
    if (!context.mounted) return;
    final match = plans.where(
      (plan) =>
          plan.durationValue == m.durationValue &&
          plan.durationUnit == m.durationUnit,
    );
    final r = await showRenewDialog(
      context,
      plans: plans,
      initialDurationValue: m.durationValue,
      initialDurationUnit: m.durationUnit,
      initialAmount: match.isNotEmpty ? match.first.fee : m.fee,
    );
    if (r == null) return;
    await AppDb.i.renew(
      m,
      planLabel(r.durationValue, r.durationUnit),
      r.durationValue,
      r.durationUnit,
      r.amount,
      method: r.method,
    );
    if (context.mounted) {
      snack(
        context,
        'Membership renewed for ${planLabel(r.durationValue, r.durationUnit)}',
      );
    }
  }

  String? _whatsAppNumber(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.length == 10) {
      digits = '91$digits';
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = '91${digits.substring(1)}';
    }
    return digits.length >= 8 && digits.length <= 15 ? digits : null;
  }

  String _renewalMessage(Member m) {
    final expiry = DateFormat('dd MMM yyyy').format(m.expiryDate);
    final membership =
        '${planTitle(m.durationValue, m.durationUnit)} membership';
    if (m.daysLeft < 0) {
      final days = -m.daysLeft;
      return 'Hi ${m.name}, your $membership at THE POWER CAVE expired on $expiry '
          '($days ${days == 1 ? 'day' : 'days'} ago). Please renew your membership '
          'to continue your training.';
    }
    if (m.daysLeft == 0) {
      return 'Hi ${m.name}, your $membership at THE POWER CAVE expires today. '
          'Please renew your membership to continue your training.';
    }
    return 'Hi ${m.name}, your $membership at THE POWER CAVE has ${m.daysLeft} '
        '${m.daysLeft == 1 ? 'day' : 'days'} remaining and expires on $expiry. '
        'Please plan your renewal to continue your training.';
  }

  Future<void> _whatsApp(BuildContext context, Member m) async {
    if (m.phone.trim().isEmpty) {
      snack(context, 'Add a phone number to this member first.');
      return;
    }
    final phone = _whatsAppNumber(m.phone);
    if (phone == null) {
      snack(context, 'Enter a valid phone number with country code.');
      return;
    }
    final uri = Uri.https('wa.me', '/$phone', {'text': _renewalMessage(m)});
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

  Future<void> _call(BuildContext context, Member m) async {
    final number = m.phone.trim();
    if (number.isEmpty) {
      snack(context, 'Add a phone number to this member first.');
      return;
    }
    if (!RegExp(r'\d').hasMatch(number)) {
      snack(context, 'No valid phone number is saved for this member.');
      return;
    }
    try {
      final launched = await launchUrl(
        Uri(scheme: 'tel', path: number),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        snack(context, 'Could not open the phone dialer on this device.');
      }
    } on PlatformException {
      if (context.mounted) {
        snack(context, 'Could not open the phone dialer on this device.');
      }
    }
  }

  Future<void> _editPr(BuildContext context, Member m) async {
    var value = m.prKg > 0
        ? m.prKg.toStringAsFixed(m.prKg % 1 == 0 ? 0 : 1)
        : '';
    final result = await showDialog<double>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text(
          'Current PR (kg)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: TextFormField(
          initialValue: value,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => value = v,
          decoration: fieldDeco(
            hint: 'e.g. 140',
            icon: Icons.emoji_events_outlined,
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
    if (result != null && result >= 0) {
      await AppDb.i.setPr(m.id!, result);
    }
  }

  Future<void> _photo(BuildContext context, Member m) async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 480,
        imageQuality: 80,
      );
      if (x == null) return;
      await AppDb.i.setPhoto(m.id!, await x.readAsBytes());
    } catch (_) {
      if (context.mounted) {
        snack(context, 'Could not open the photo picker on this device.');
      }
    }
  }

  Future<void> _delete(BuildContext context, Member m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete member?'),
        content: const Text(
          'Member data will be removed. Finance history will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: warnRed),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AppDb.i.deleteMember(m.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _receipt(BuildContext context, Member m, List<Payment> pays) {
    if (pays.isEmpty) {
      snack(context, 'No payments to print yet');
      return;
    }
    final p = pays.first;
    final text =
        'RTS PHYSIO MANAGEMENT - Payment Receipt\n'
        'Member: ${m.name} (${m.code})\n'
        'Plan: ${p.plan.isEmpty ? m.plan : p.plan}\n'
        'Amount: ${inr2(p.amount)}\n'
        'Method: ${p.method}\n'
        'Paid on: ${DateFormat('dd MMM yyyy, hh:mm a').format(p.paidAt)}\n'
        'Valid till: ${DateFormat('dd MMM yyyy').format(m.expiryDate)}';
    Clipboard.setData(ClipboardData(text: text));
    snack(context, 'Receipt copied to clipboard');
  }

  // ----------------------------------------------------------- widgets
  Widget _stat(
    IconData icon,
    Color c,
    Color bg,
    String value,
    String label, {
    VoidCallback? onTap,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: c, size: 26),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _payRow(Payment p) {
    final adj = p.type == 'adjustment';
    final title = adj
        ? 'Advance Payment (${inr(p.amount)})'
        : '${p.plan.isEmpty ? 'Treatment Plan' : p.plan} Paid (${inr(p.amount)})';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lineGrey),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: okSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: okGreen),
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
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(p.paidAt)} via ${p.method}',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+ ${inr2(p.amount)}',
                  style: const TextStyle(
                    color: okGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  adj ? 'Advance' : 'Verified',
                  style: const TextStyle(color: muted, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    Color iconColor,
    Color bg,
    VoidCallback onTap, {
    Widget? leading,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: lineGrey),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading ?? Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _seeAll(BuildContext context, List<Payment> pays) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(c).size.height * 0.75,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            const Text(
              'All payments',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final p in pays) _payRow(p),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          bottom: false,
          child: Live<_P>(
            load: _load,
            builder: (context, p) {
              final m = p.m;
              if (m == null) {
                return Column(
                  children: const [
                    PageHeader('Patient Profile'),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Member not found',
                          style: TextStyle(color: muted),
                        ),
                      ),
                    ),
                  ],
                );
              }
              final st = m.state;
              final cycleStart = addDuration(
                m.expiryDate,
                -m.durationValue,
                m.durationUnit,
              );
              final totalDays = m.expiryDate.difference(cycleStart).inDays;
              final double progress = totalDays <= 0
                  ? 0.0
                  : (m.daysLeft / totalDays).clamp(0.0, 1.0).toDouble();
              final perDuration =
                  m.fee / (m.durationValue < 1 ? 1 : m.durationValue);

              final Widget statusPill = switch (st) {
                MStatus.active => const Pill(
                  'Active',
                  bg: okSoft,
                  fg: okGreen,
                  icon: Icons.circle,
                ),
                MStatus.dueSoon => const Pill(
                  'Due soon',
                  bg: Color(0xffffe9c7),
                  fg: Color(0xffb86e00),
                  icon: Icons.schedule,
                ),
                MStatus.inactive => const Pill(
                  'Inactive',
                  bg: Color(0xffe9ebef),
                  fg: muted,
                ),
                MStatus.expired => const Pill(
                  'Expired',
                  bg: Color(0xffe9ebef),
                  fg: muted,
                ),
              };

              return Column(
                children: [
                  PageHeader(
                    'Patient Profile',
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: ink),
                      onSelected: (v) {
                        if (v == 'photo') _photo(context, m);
                        if (v == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMember(member: m),
                            ),
                          );
                        }
                        if (v == 'delete') _delete(context, m);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit member'),
                        ),
                        PopupMenuItem(
                          value: 'photo',
                          child: Text('Change photo'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete member',
                            style: TextStyle(color: warnRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TopSheet(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                        children: [
                          // ------------------------------- identity
                          Row(
                            children: [
                              Stack(
                                children: [
                                  MemberAvatar(m, radius: 38),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: GestureDetector(
                                      onTap: () => _photo(context, m),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: orange,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 12,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${m.code}',
                                      style: const TextStyle(color: muted),
                                    ),
                                    if (m.phone.isNotEmpty)
                                      Text(
                                        m.phone,
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              statusPill,
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Pill('${m.age} yrs'),
                              Pill(m.gender),
                              Pill(
                                tierName(m.durationValue, m.durationUnit),
                                bg: orangeSoft,
                                fg: const Color(0xffb86e00),
                                icon: Icons.shield_outlined,
                                border: orange,
                              ),
                              if (m.keycard.isNotEmpty)
                                Pill(
                                  m.keycard,
                                  icon: Icons.credit_card_outlined,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _action(
                                Icons.chat_rounded,
                                'WhatsApp',
                                Colors.white,
                                const Color(0xff25d366),
                                () => _whatsApp(context, m),
                                leading: FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              _action(
                                Icons.call_rounded,
                                'Call',
                                Colors.white,
                                const Color(0xff2563eb),
                                () => _call(context, m),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddMember(member: m),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Member'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ink,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: lineGrey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ----------------------------------- stats
                          Row(
                            children: [
                              _stat(
                                Icons.local_fire_department_rounded,
                                orange,
                                orangeSoft,
                                '${p.streak}',
                                'Days Streak',
                              ),
                              _stat(
                                Icons.event_available_rounded,
                                blue,
                                blueSoft,
                                '${p.total}',
                                'Total Check-ins',
                              ),
                              _stat(
                                Icons.emoji_events_rounded,
                                const Color(0xffb86e00),
                                const Color(0xfffff4d6),
                                m.prKg > 0
                                    ? '${m.prKg.toStringAsFixed(m.prKg % 1 == 0 ? 0 : 1)} kg'
                                    : '-',
                                'Current PR',
                                onTap: () => _editPr(context, m),
                              ),
                            ],
                          ),
                          // -------------------------------- membership
                          SectionTitle(
                            'Treatment Plan',
                            action: 'Renew',
                            onAction: () => _renew(context, m),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: lineGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${planTitle(m.durationValue, m.durationUnit)} Plan',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 9,
                                    backgroundColor: const Color(0xffeceef2),
                                    color: m.lapsed ? warnRed : orange,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  m.lapsed
                                      ? 'Expired ${-m.daysLeft} days ago'
                                      : '${m.daysLeft} Days Left',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: m.lapsed
                                        ? warnRed
                                        : const Color(0xffb86e00),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${DateFormat('dd MMM yyyy').format(cycleStart)} - ${DateFormat('dd MMM yyyy').format(m.expiryDate)}',
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${inr(perDuration)} / ${durationUnitLabel(m.durationUnit).toLowerCase()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ------------------------------ payment history
                          SectionTitle(
                            'Payment History',
                            action: p.pays.length > 3 ? 'See All' : null,
                            onAction: () => _seeAll(context, p.pays),
                          ),
                          if (p.pays.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No payments recorded yet.',
                                style: TextStyle(color: muted),
                              ),
                            ),
                          for (final pay in p.pays.take(3)) _payRow(pay),
                          // ---------------------------- quick actions
                          const SectionTitle('Quick Actions'),
                          Row(
                            children: [
                              _action(
                                Icons.autorenew_rounded,
                                'Renew Treatment',
                                orange,
                                orangeSoft,
                                () => _renew(context, m),
                              ),
                              _action(
                                Icons.print_outlined,
                                'Print Receipt',
                                ink,
                                Colors.white,
                                () => _receipt(context, m, p.pays),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _action(
                                m.status == 'active'
                                    ? Icons.person_off_outlined
                                    : Icons.verified_user_outlined,
                                m.status == 'active'
                                    ? 'Mark Inactive'
                                    : 'Activate',
                                ink,
                                Colors.white,
                                () => AppDb.i.setStatus(
                                  m.id!,
                                  m.status != 'active',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
