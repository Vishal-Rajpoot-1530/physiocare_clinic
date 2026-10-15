import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../models/member.dart';
import '../widgets/common.dart';
import '../widgets/live.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  Future<void> _edit(BuildContext context, List<PlanOption> all, PlanOption? existing) async {
    final others = all
        .where(
          (plan) =>
              plan.durationValue != existing?.durationValue ||
              plan.durationUnit != existing?.durationUnit,
        )
        .toList();
    final r = await showDialog<PlanOption>(
      context: context,
      builder: (_) => _PlanDialog(
        existing: existing,
        takenDurations: others.map(_durationKey).toSet(),
      ),
    );
    if (r == null) return;
    final next = [...others, r]
      ..sort((a, b) {
        final unitOrder = a.durationUnit.index.compareTo(b.durationUnit.index);
        return unitOrder != 0
            ? unitOrder
            : a.durationValue.compareTo(b.durationValue);
      });
    await AppDb.i.setPlans(next);
    if (context.mounted) snack(context, existing == null ? 'Plan added' : 'Plan updated');
  }

  String _durationKey(PlanOption plan) =>
      '${plan.durationUnit.name}:${plan.durationValue}';

  Future<void> _delete(BuildContext context, List<PlanOption> all, PlanOption p) async {
    if (all.length <= 1) {
      snack(context, 'At least one plan is required.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text('${p.label} (${inr(p.fee)}) will be removed from the plan list. Existing members are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: warnRed),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AppDb.i.setPlans(
        all
            .where(
              (plan) =>
                  plan.durationValue != p.durationValue ||
                  plan.durationUnit != p.durationUnit,
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            const PageHeader('Membership Plans', subtitle: 'Set duration unit and amount'),
            Expanded(
              child: TopSheet(
                color: pageBg,
                child: Live<List<PlanOption>>(
                  load: AppDb.i.plans,
                  fallbackData: kPlans,
                  builder: (context, plans) => Column(children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        children: [
                          if (plans.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.card_membership_outlined,
                                    size: 48,
                                    color: muted,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No plans yet. Add a plan or reset to defaults.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          for (final p in plans)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                              child: Row(children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: orangeSoft, borderRadius: BorderRadius.circular(12)),
                                  child: Text('${p.durationValue}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ink)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                                    Text(p.sub, style: const TextStyle(color: muted, fontSize: 12)),
                                  ]),
                                ),
                                Text(inr(p.fee),
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: orange, fontSize: 16)),
                                IconButton(
                                  onPressed: () => _edit(context, plans, p),
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                ),
                                IconButton(
                                  onPressed: () => _delete(context, plans, p),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: warnRed),
                                ),
                              ]),
                            ),
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton(
                              onPressed: () async {
                                await AppDb.i.setPlans(List<PlanOption>.of(kPlans));
                                if (context.mounted) snack(context, 'Plans reset to defaults');
                              },
                              child: const Text('Reset to defaults', style: TextStyle(color: muted)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      child: PrimaryButton('Add Plan', icon: Icons.add_rounded, onPressed: () => _edit(context, plans, null)),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PlanDialog extends StatefulWidget {
  final PlanOption? existing;
  final Set<String> takenDurations;
  const _PlanDialog({required this.existing, required this.takenDurations});

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  late final TextEditingController duration;
  late final TextEditingController amount;
  PlanDurationUnit unit = PlanDurationUnit.month;
  String? error;

  @override
  void initState() {
    super.initState();
    duration = TextEditingController(
      text: widget.existing == null
          ? ''
          : '${widget.existing!.durationValue}',
    );
    unit = widget.existing?.durationUnit ?? PlanDurationUnit.month;
    amount = TextEditingController(text: widget.existing == null ? '' : widget.existing!.fee.toStringAsFixed(0));
  }

  @override
  void dispose() {
    duration.dispose();
    amount.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(duration.text.trim());
    final amt = double.tryParse(amount.text.trim());
    if (value == null || value < 1 || value > 1200) {
      setState(() => error = 'Enter a valid duration (1 to 1200).');
      return;
    }
    if (amt == null || amt <= 0) {
      setState(() => error = 'Enter a valid amount greater than 0.');
      return;
    }
    final key = '${unit.name}:$value';
    if (widget.takenDurations.contains(key)) {
      setState(() => error = 'A ${planLabel(value, unit)} plan already exists.');
      return;
    }
    Navigator.pop(context, PlanOption.of(value, unit, amt));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.existing == null ? 'Add Plan' : 'Edit Plan',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const FieldLabel('Duration', required: true),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: duration,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() => error = null),
                  decoration: fieldDeco(icon: Icons.schedule, hint: 'e.g. 2'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<PlanDurationUnit>(
                  initialValue: unit,
                  decoration: fieldDeco(hint: 'Unit'),
                  items: PlanDurationUnit.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(durationUnitLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (next) {
                    if (next == null) return;
                    setState(() {
                      unit = next;
                      error = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const FieldLabel('Amount (₹)', required: true),
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => error = null),
            decoration: fieldDeco(icon: Icons.currency_rupee_rounded, hint: 'Type amount'),
          ),
          if (error != null) ErrorBanner(error!),
          const SizedBox(height: 18),
          PrimaryButton('Save Plan', icon: Icons.check_rounded, onPressed: _save),
          const SizedBox(height: 10),
          CancelButton(onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}
