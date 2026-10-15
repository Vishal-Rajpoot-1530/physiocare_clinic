import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_db.dart';
import '../models/member.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String filter = 'All';

  static const _filters = ['All', 'Joining', 'Renewal', 'Other'];

  bool _match(Payment p) {
    switch (filter) {
      case 'Joining':
        return p.type == 'joining';
      case 'Renewal':
        return p.type == 'renewal';
      case 'Other':
        return p.type != 'joining' && p.type != 'renewal';
      default:
        return true;
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'joining':
        return Icons.person_add_alt_1_rounded;
      case 'renewal':
        return Icons.autorenew_rounded;
      default:
        return Icons.tune_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'joining':
        return 'Joining fee';
      case 'renewal':
        return 'Renewal';
      default:
        return 'Adjustment';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        const TabHeader('Finances'),
        Expanded(
          child: TopSheet(
            color: pageBg,
            child: Live<List<Payment>>(
              load: AppDb.i.payments,
              fallbackData: const [],
              builder: (context, all) {
                final now = DateTime.now();
                final total = all.fold<double>(0, (a, p) => a + p.amount);

                // last 6 months totals (oldest -> newest)
                final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
                final sums = months
                    .map((mo) => all
                        .where((p) => p.paidAt.year == mo.year && p.paidAt.month == mo.month)
                        .fold<double>(0, (a, p) => a + p.amount))
                    .toList();
                final thisMonth = sums.last;
                final lastMonth = sums[sums.length - 2];
                final delta = lastMonth > 0 ? (thisMonth - lastMonth) / lastMonth * 100 : null;
                final maxSum = sums.fold<double>(0, (a, b) => b > a ? b : a);

                final rows = all.where(_match).toList();

                return RefreshIndicator(
                  color: orange,
                  onRefresh: refreshAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      // ------------------------------- summary card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Expanded(
                              child: Text('This Month',
                                  style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
                            ),
                            if (delta != null)
                              Pill(
                                '${delta >= 0 ? '↗' : '↘'} ${delta.abs().toStringAsFixed(1)}%',
                                bg: delta >= 0 ? okSoft : redSoft,
                                fg: delta >= 0 ? okGreen : warnRed,
                              ),
                          ]),
                          const SizedBox(height: 4),
                          Text(inr2(thisMonth),
                              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text('Total collected ${inr(total)}  •  ${all.length} transactions',
                              style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 96,
                            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              for (var i = 0; i < months.length; i++)
                                Expanded(
                                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                    Container(
                                      width: 22,
                                      height: maxSum <= 0 ? 4 : (sums[i] / maxSum * 64).clamp(4.0, 64.0).toDouble(),
                                      decoration: BoxDecoration(
                                        color: i == months.length - 1 ? orange : Colors.white24,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(DateFormat('MMM').format(months[i]),
                                        style: TextStyle(
                                          color: i == months.length - 1 ? orange : Colors.white54,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ]),
                                ),
                            ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      // ----------------------------------- filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final f in _filters)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setState(() => filter = f),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: filter == f ? orange : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: filter == f ? orange : lineGrey),
                                  ),
                                  child: Text(f,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: filter == f ? ink : muted)),
                                ),
                              ),
                            ),
                        ]),
                      ),
                      const SectionTitle('Transactions'),
                      if (rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(children: [
                            Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              'No payments yet.\nAdd a member or renew a plan to see revenue here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
                      for (final p in rows)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(color: orangeSoft, borderRadius: BorderRadius.circular(12)),
                              child: Icon(_icon(p.type), color: orange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p.memberName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_typeLabel(p.type)}${p.plan.isEmpty ? '' : '  •  ${p.plan}'}  •  ${p.method}',
                                  style: const TextStyle(color: muted, fontSize: 12),
                                ),
                                Text(DateFormat('dd MMM yyyy, hh:mm a').format(p.paidAt),
                                    style: const TextStyle(color: muted, fontSize: 11.5)),
                              ]),
                            ),
                            Text('+ ${inr2(p.amount)}',
                                style: const TextStyle(color: okGreen, fontWeight: FontWeight.w900)),
                          ]),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
