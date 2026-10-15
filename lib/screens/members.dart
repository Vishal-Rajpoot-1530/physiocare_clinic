import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_db.dart';
import '../models/member.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';
import 'add_member.dart';
import 'profile.dart';

/// Lets other screens (dashboard) jump to the members tab with a filter applied.
final ValueNotifier<String> memberFilter = ValueNotifier<String>('All');

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String q = '';
  String filter = memberFilter.value;

  @override
  void initState() {
    super.initState();
    memberFilter.addListener(_sync);
  }

  @override
  void dispose() {
    memberFilter.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() => filter = memberFilter.value);
  }

  bool _matches(Member m) {
    switch (filter) {
      case 'Active':
        return m.state == MStatus.active || m.state == MStatus.dueSoon;
      case 'Expiring':
        return m.state == MStatus.dueSoon;
      case 'Expired':
        return m.state == MStatus.expired;
      case 'Inactive':
        return m.state == MStatus.inactive;
      default:
        return true;
    }
  }

  bool _search(Member m) {
    if (q.isEmpty) return true;
    final s = q.toLowerCase();
    return m.name.toLowerCase().contains(s) ||
        m.phone.contains(q) ||
        m.code.toLowerCase().contains(s) ||
        m.keycard.toLowerCase().contains(s) ||
        (m.id?.toString() == q);
  }

  Widget _chip(String label, int count, bool selected) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => memberFilter.value = label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? orange : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? orange : lineGrey),
            ),
            child: Text('$label ($count)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? ink : muted)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        const TabHeader('Patients'),
        Expanded(
          child: TopSheet(
            color: pageBg,
            child: Live<List<Member>>(
              load: AppDb.i.members,
              fallbackData: const [],
              builder: (context, all) {
                final list = all.where(_matches).where(_search).toList();
                int count(bool Function(Member) f) => all.where(f).length;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: TextField(
                      onChanged: (v) => setState(() => q = v.trim()),
                      decoration: fieldDeco(hint: 'Search by name, phone or patient ID...', icon: Icons.search_rounded)
                          .copyWith(fillColor: Colors.white),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      _chip('All', all.length, filter == 'All'),
                      _chip(
                        'Active',
                        count(
                          (m) =>
                              m.state == MStatus.active ||
                              m.state == MStatus.dueSoon,
                        ),
                        filter == 'Active',
                      ),
                      _chip('Expiring', count((m) => m.state == MStatus.dueSoon), filter == 'Expiring'),
                      _chip('Expired', count((m) => m.state == MStatus.expired), filter == 'Expired'),
                      _chip('Inactive', count((m) => m.state == MStatus.inactive), filter == 'Inactive'),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RefreshIndicator(
                      color: orange,
                      onRefresh: refreshAll,
                      child: list.isEmpty
                          ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                              const SizedBox(height: 90),
                              Icon(Icons.groups_2_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  all.isEmpty ? 'No members yet.\nTap "Add Member" to enroll your first athlete.' : 'No members found',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ])
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              itemCount: list.length,
                              itemBuilder: (context, i) => _MemberCard(list[i]),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                    child: PrimaryButton(
                      'Add Patient',
                      icon: Icons.add_rounded,
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const AddMember())),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Member m;
  const _MemberCard(this.m);

  @override
  Widget build(BuildContext context) {
    final days = m.daysLeft;
    final st = m.state;

    Widget status;
    switch (st) {
      case MStatus.active:
        status = const Pill('Active', bg: okSoft, fg: okGreen, icon: Icons.circle);
        break;
      case MStatus.dueSoon:
        status = Pill(days == 0 ? 'Due today' : 'Due in $days days',
            bg: const Color(0xffffe9c7), fg: const Color(0xffb86e00), icon: Icons.shield_outlined);
        break;
      case MStatus.inactive:
        status = const Pill('Inactive', bg: Color(0xffe9ebef), fg: muted, icon: Icons.star_border_rounded);
        break;
      case MStatus.expired:
        status = const Pill('Expired', bg: Color(0xffe9ebef), fg: muted, icon: Icons.history_rounded);
        break;
    }

    IconData lineIcon = Icons.schedule;
    Color lineColor = muted;
    String line;
    if (st == MStatus.expired) {
      line = 'Expired ${-days} days ago (${DateFormat('MMM dd').format(m.expiryDate)})';
    } else if (st == MStatus.inactive) {
      line = 'Marked inactive  •  valid till ${DateFormat('dd MMM').format(m.expiryDate)}';
    } else if (st == MStatus.dueSoon) {
      lineIcon = Icons.warning_amber_rounded;
      lineColor = warnRed;
      line = days == 0
          ? 'Renewal due today (${DateFormat('dd MMM').format(m.expiryDate)})'
          : 'Renewal due in $days days (${DateFormat('dd MMM').format(m.expiryDate)})';
    } else if (m.durationUnit == PlanDurationUnit.month &&
        m.durationValue == 1) {
      line = 'Cycles on ${DateFormat('MMM').format(m.expiryDate)} ${ordinal(m.expiryDate.day)}';
    } else {
      line = 'Renews in $days days (${DateFormat('MMM yyyy').format(m.expiryDate)})';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(id: m.id!))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MemberAvatar(m, radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(m.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    ),
                    if (st == MStatus.active) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded, color: blue, size: 17),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('ID: ${m.code}', style: const TextStyle(color: muted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    Pill(planTitle(m.durationValue, m.durationUnit)),
                    Pill('${m.age} yrs  •  ${m.gender}'),
                  ]),
                ]),
              ),
              status,
            ]),
            const Divider(height: 22, color: lineGrey),
            Row(children: [
              Icon(lineIcon, size: 17, color: lineColor),
              const SizedBox(width: 7),
              Expanded(
                child: Text(line,
                    style: TextStyle(color: lineColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ]),
          ]),
        ),
      ),
    );
  }
}
