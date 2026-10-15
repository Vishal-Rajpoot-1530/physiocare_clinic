import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_db.dart';
import '../models/member.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final code = TextEditingController();
  Member? found;
  String? message;
  bool good = false;
  bool busy = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> checkIn() async {
    final raw = code.text.trim();
    if (raw.isEmpty) return;
    setState(() => busy = true);
    try {
      final m = await AppDb.i.findByCode(raw);
      if (!mounted) return;
      if (m == null) {
        setState(() {
          found = null;
          good = false;
          message = 'No member found for "$raw"';
        });
        return;
      }
      if (m.state == MStatus.inactive || m.state == MStatus.expired) {
        setState(() {
          found = m;
          good = false;
          message = m.lapsed ? 'Membership expired ${-m.daysLeft} day(s) ago. Please renew.' : 'Member is marked inactive.';
        });
        return;
      }
      final created = await AppDb.i.checkIn(m.id!);
      if (!mounted) return;
      setState(() {
        found = m;
        good = true;
        message = created
            ? 'Checked in. ${m.daysLeft} day(s) left on plan.'
            : 'Already checked in today.';
      });
      if (created) code.clear();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            const PageHeader('Check In', subtitle: 'Tap keycard or enter ID / phone'),
            Expanded(
              child: TopSheet(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const FieldLabel('Keycard / Member ID / Phone'),
                    TextField(
                      controller: code,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => checkIn(),
                      decoration: fieldDeco(hint: 'e.g. PC-123456 or MV-0004', icon: Icons.credit_card_outlined),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton('Check In', icon: Icons.login_rounded, busy: busy, onPressed: checkIn),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: good ? okSoft : redSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(children: [
                          if (found != null) ...[MemberAvatar(found!, radius: 24), const SizedBox(width: 12)],
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (found != null)
                                Text(found!.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              Text(message!,
                                  style: TextStyle(color: good ? okGreen : warnRed, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ]),
                      ),
                    ],
                    const SectionTitle("Today's check-ins"),
                    Live<List<Map<String, Object?>>>(
                      load: AppDb.i.todayCheckins,
                      placeholder: const SizedBox(height: 40),
                      builder: (c, rows) {
                        if (rows.isEmpty) {
                          return const Text('Nobody has checked in yet today.', style: TextStyle(color: muted));
                        }
                        return Column(children: [
                          for (final r in rows)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: okSoft,
                                child: Icon(Icons.check_rounded, color: okGreen),
                              ),
                              title: Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              trailing: Text(
                                DateFormat('hh:mm a').format(DateTime.parse(r['at'] as String)),
                                style: const TextStyle(color: muted),
                              ),
                            ),
                        ]);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
