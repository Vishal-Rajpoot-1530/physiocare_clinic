import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_db.dart';
import '../models/member.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';
import 'members.dart';
import 'scan.dart';

class _Dash {
  final int total, active, dueSoon, lapsed, newThisWeek;
  final double mtd, last, goal;
  const _Dash(
    this.total,
    this.active,
    this.dueSoon,
    this.lapsed,
    this.newThisWeek,
    this.mtd,
    this.last,
    this.goal,
  );
}

const _emptyDash = _Dash(0, 0, 0, 0, 0, 0, 0, 0);

Future<_Dash> _load() async {
  final members = await AppDb.i.members();
  final pays = await AppDb.i.payments();
  final goal = await AppDb.i.goal();
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1);
  double mtd = 0, last = 0;
  for (final p in pays) {
    if (p.paidAt.year == now.year && p.paidAt.month == now.month) {
      mtd += p.amount;
    } else if (p.paidAt.year == lastMonth.year &&
        p.paidAt.month == lastMonth.month) {
      last += p.amount;
    }
  }
  final weekAgo = now.subtract(const Duration(days: 7));
  return _Dash(
    members.length,
    members
        .where(
          (m) => m.state == MStatus.active || m.state == MStatus.dueSoon,
        )
        .length,
    members.where((m) => m.state == MStatus.dueSoon).length,
    members.where((m) => m.state == MStatus.expired).length,
    members.where((m) => m.createdAt.isAfter(weekAgo)).length,
    mtd,
    last,
    goal,
  );
}

class Dashboard extends StatelessWidget {
  final void Function(int tab) onGo;
  const Dashboard({super.key, required this.onGo});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _hero() {
    const h = 172.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: h,
        child: Stack(
          children: [
            // hero photo (dark on the left for text, lifter on the right)
            Positioned.fill(
              child: Image.asset(
                'assets/images/herosection.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            // keep the left side dark so the text stays readable
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0x990b0d10), Color(0x4d0b0d10), Color(0x000b0d10)],
                    stops: [0, 0.4, 0.65],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                  const Text(
                    'DOCTOR!',
                    style: TextStyle(color: orange, fontSize: 25, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  const Text("Here's what's happening today", style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
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

  Widget _tile(IconData icon, String label, bool hot, VoidCallback onTap) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: hot ? orange : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26, color: ink),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // blurred gym backdrop (shows through at the bottom, like the design)
        Positioned.fill(
          child: Image.asset(
            'assets/images/homebg.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  night.withValues(alpha: 0.92),
                  night.withValues(alpha: 0.55),
                  night.withValues(alpha: 0.10),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
        ),
        _content(context),
      ],
    );
  }

  Widget _content(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const TabHeader('Dashboard', brand: true),
          Expanded(
            child: Live<_Dash>(
              load: _load,
              fallbackData: _emptyDash,
              builder: (context, d) {
                final pct = d.goal > 0 ? d.mtd / d.goal * 100 : 0.0;
                final delta = d.last > 0
                    ? (d.mtd - d.last) / d.last * 100
                    : null;
                final util = d.total > 0 ? d.active / d.total * 100 : 0.0;
                return RefreshIndicator(
                  color: orange,
                  onRefresh: refreshAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      // ---------------------------------------------- hero
                      _hero(),
                      const SizedBox(height: 12),
                      // ------------------------------------ quick actions
                      Row(
                        children: [
                          _tile(Icons.people_alt_outlined, 'Patients', true, () {
                            memberFilter.value = 'All';
                            onGo(1);
                          }),
                          _tile(
                            Icons.credit_card_rounded,
                            'Payments',
                            false,
                            () => onGo(2),
                          ),
                          _tile(
                            Icons.qr_code_scanner_rounded,
                            'Check In',
                            false,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanScreen(),
                                ),
                              );
                            },
                          ),
                          _tile(
                            Icons.bar_chart_rounded,
                            'Reports',
                            false,
                            () => onGo(2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ------------------------------------------ revenue
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total Revenue (MTD)',
                                    style: TextStyle(
                                      color: muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (delta != null)
                                  Pill(
                                    '${delta >= 0 ? '↗' : '↘'} ${delta.abs().toStringAsFixed(1)}%',
                                    bg: delta >= 0 ? okSoft : redSoft,
                                    fg: delta >= 0 ? okGreen : warnRed,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              inr(d.mtd),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: ink,
                              ),
                            ),
                            Text(
                              'vs ${inr(d.last)} last month',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (pct / 100).clamp(0.0, 1.0).toDouble(),
                                minHeight: 9,
                                backgroundColor: const Color(0xffeceef2),
                                color: orange,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${pct.toStringAsFixed(1)}% of ${compactInr(d.goal)} goal',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ------------------------------------------ members
                      Row(
                        children: [
                          Expanded(
                            child: _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Patients',
                                    style: TextStyle(
                                      color: muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: okGreen,
                                        size: 20,
                                      ),
                                      Text(
                                        '${d.total}',
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '↑ ${d.newThisWeek} this week',
                                    style: const TextStyle(
                                      color: okGreen,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Patients',
                                    style: TextStyle(
                                      color: muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: okGreen,
                                        size: 20,
                                      ),
                                      Text(
                                        '${d.active}',
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${util.toStringAsFixed(1)}% utilization',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // -------------------------------------- expiring soon
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          memberFilter.value = 'Expiring';
                          onGo(1);
                        },
                        child: _card(
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: redSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.event_available_outlined,
                                  color: warnRed,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Expiring Soon',
                                      style: TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${d.dueSoon} Members',
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'Expiring this week  •  ${d.lapsed} lapsed',
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: redSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: warnRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}