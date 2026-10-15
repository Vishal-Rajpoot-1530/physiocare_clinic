import 'package:flutter/material.dart';

import '../models/member.dart';
import 'common.dart';

typedef RenewResult = ({
  int durationValue,
  PlanDurationUnit durationUnit,
  double amount,
  String method,
});

Future<RenewResult?> showRenewDialog(
  BuildContext context, {
  required List<PlanOption> plans,
  required int initialDurationValue,
  required PlanDurationUnit initialDurationUnit,
  required double initialAmount,
}) {
  return showDialog<RenewResult>(
    context: context,
    builder: (_) => _RenewDialog(
      plans: plans,
      initialDurationValue: initialDurationValue,
      initialDurationUnit: initialDurationUnit,
      initialAmount: initialAmount,
    ),
  );
}

class _RenewDialog extends StatefulWidget {
  final List<PlanOption> plans;
  final int initialDurationValue;
  final PlanDurationUnit initialDurationUnit;
  final double initialAmount;
  const _RenewDialog({
    required this.plans,
    required this.initialDurationValue,
    required this.initialDurationUnit,
    required this.initialAmount,
  });

  @override
  State<_RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends State<_RenewDialog> {
  late final TextEditingController duration;
  late final TextEditingController amount;
  late PlanDurationUnit unit;
  String method = 'Cash';
  String? error;

  @override
  void initState() {
    super.initState();
    duration = TextEditingController(text: '${widget.initialDurationValue}');
    unit = widget.initialDurationUnit;
    amount = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    duration.dispose();
    amount.dispose();
    super.dispose();
  }

  void _pick(PlanOption p) {
    setState(() {
      duration.text = '${p.durationValue}';
      unit = p.durationUnit;
      amount.text = p.fee.toStringAsFixed(0);
      error = null;
    });
  }

  void _onDuration(String v) {
    final n = int.tryParse(v.trim());
    setState(() {
      error = null;
      _syncPlanAmount(n);
    });
  }

  void _syncPlanAmount(int? value) {
    if (value == null) return;
    final match = widget.plans.where(
      (p) => p.durationValue == value && p.durationUnit == unit,
    );
    if (match.isNotEmpty) amount.text = match.first.fee.toStringAsFixed(0);
  }

  void _submit() {
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
    Navigator.pop(context, (
      durationValue: value,
      durationUnit: unit,
      amount: amt,
      method: method,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse(duration.text.trim());
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Renew Membership',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pick a plan or enter a duration and unit.',
              style: TextStyle(color: muted, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in widget.plans)
                  ChoiceChip(
                    label: Text('${p.label}  •  ${inr(p.fee)}'),
                    selected:
                        current == p.durationValue && unit == p.durationUnit,
                    selectedColor: orange,
                    onSelected: (_) => _pick(p),
                  ),
              ],
            ),
            const FieldLabel('Duration', required: true),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: duration,
                    keyboardType: TextInputType.number,
                    onChanged: _onDuration,
                    decoration: fieldDeco(icon: Icons.schedule, hint: 'e.g. 2'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<PlanDurationUnit>(
                    key: ValueKey(unit),
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
                        _syncPlanAmount(int.tryParse(duration.text.trim()));
                      });
                    },
                  ),
                ),
              ],
            ),
            const FieldLabel('Amount (₹)', required: true),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => error = null),
              decoration: fieldDeco(
                icon: Icons.currency_rupee_rounded,
                hint: 'Type amount',
              ),
            ),
            const FieldLabel('Payment method'),
            Wrap(
              spacing: 8,
              children: [
                for (final k in kMethods)
                  ChoiceChip(
                    label: Text(k),
                    selected: method == k,
                    selectedColor: orange,
                    onSelected: (_) => setState(() => method = k),
                  ),
              ],
            ),
            if (error != null) ErrorBanner(error!),
            const SizedBox(height: 18),
            PrimaryButton(
              'Renew',
              icon: Icons.check_rounded,
              onPressed: _submit,
            ),
            const SizedBox(height: 10),
            CancelButton(onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
