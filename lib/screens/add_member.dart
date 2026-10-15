import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../db/app_db.dart';
import '../models/member.dart';
import '../widgets/common.dart';

class AddMember extends StatefulWidget {
  final Member? member;
  const AddMember({super.key, this.member});

  @override
  State<AddMember> createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMember> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final age = TextEditingController(text: '25');
  final fee = TextEditingController(text: '400.00');
  final duration = TextEditingController(text: '1');
  final keycard = TextEditingController();

  String gender = 'Male';
  int durationValue = 1;
  PlanDurationUnit durationUnit = PlanDurationUnit.day;
  DateTime join = dayOnly(DateTime.now());
  Uint8List? photo;
  bool saving = false;
  bool membershipEdited = false;
  List<PlanOption> plans = kPlans;

  @override
  void initState() {
    super.initState();
    final existing = widget.member;
    if (existing != null) {
      name.text = existing.name;
      phone.text = existing.phone;
      age.text = '${existing.age}';
      fee.text = existing.fee.toStringAsFixed(2);
      duration.text = '${existing.durationValue}';
      keycard.text = existing.keycard;
      gender = existing.gender;
      durationValue = existing.durationValue;
      durationUnit = existing.durationUnit;
      join = dayOnly(existing.joiningDate);
      photo = existing.photo;
    }
    AppDb.i.plans().then((p) {
      if (!mounted) return;
      setState(() {
        plans = p;
        if (existing == null) {
          final match = p.where(
            (x) =>
                x.durationValue == durationValue &&
                x.durationUnit == durationUnit,
          );
          if (match.isNotEmpty) fee.text = match.first.fee.toStringAsFixed(2);
        }
      });
    });
  }

  @override
  void dispose() {
    for (final c in [name, phone, age, fee, duration, keycard]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get expiry {
    final existing = widget.member;
    if (existing != null && !membershipEdited) return existing.expiryDate;
    return addDuration(join, durationValue, durationUnit);
  }

  void pickPlan(PlanOption p) {
    setState(() {
      membershipEdited = true;
      durationValue = p.durationValue;
      durationUnit = p.durationUnit;
      duration.text = '${p.durationValue}';
      fee.text = p.fee.toStringAsFixed(2);
    });
  }

  void onCustom(String v) {
    final n = int.tryParse(v);
    if (n == null || n < 1 || n > 120) return;
    setState(() {
      membershipEdited = true;
      durationValue = n;
      final match = plans.where(
        (p) => p.durationValue == n && p.durationUnit == durationUnit,
      );
      final base = plans.where(
        (p) =>
            p.durationValue == 1 &&
            p.durationUnit == durationUnit,
      );
      final perUnit = base.isNotEmpty
          ? base.first.fee
          : switch (durationUnit) {
              PlanDurationUnit.day => 400.0,
              PlanDurationUnit.week => 2500.0,
              PlanDurationUnit.month => 10000.0,
            };
      fee.text = (match.isNotEmpty ? match.first.fee : n * perUnit)
          .toStringAsFixed(2);
    });
  }

  Future<void> pickPhoto() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 480,
        imageQuality: 80,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (mounted) setState(() => photo = bytes);
    } catch (_) {
      if (mounted) {
        snack(context, 'Could not open the photo picker on this device.');
      }
    }
  }

  void autoAssign() {
    final n = DateTime.now().millisecondsSinceEpoch % 1000000;
    keycard.text = 'PC-${n.toString().padLeft(6, '0')}';
  }

  void viewPlans() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Membership plans',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final p in plans)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${planTitle(p.durationValue, p.durationUnit)}  (${p.sub})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Text(
                  inr(p.fee),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: orange,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickPlan(p);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      initialDate: join,
    );
    if (d != null) {
      setState(() {
        join = d;
        membershipEdited = true;
      });
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final card = keycard.text.trim();
    setState(() => saving = true);
    try {
      final existing = widget.member;
      if (await AppDb.i.keycardTaken(card, exceptMemberId: existing?.id)) {
        if (mounted) {
          snack(context, 'This keycard is already assigned to another member.');
        }
        return;
      }
      final m = Member(
        id: existing?.id,
        name: name.text.trim(),
        email: existing?.email ?? '',
        phone: phone.text.trim(),
        gender: gender,
        age: int.parse(age.text.trim()),
        plan: planLabel(durationValue, durationUnit),
        durationValue: durationValue,
        durationUnit: durationUnit,
        fee: double.parse(fee.text.trim()),
        joiningDate: join,
        expiryDate: expiry,
        status: existing?.status ?? 'active',
        notes: existing?.notes ?? '',
        keycard: card,
        prKg: existing?.prKg ?? 0,
        photo: photo,
        createdAt: existing?.createdAt,
      );
      if (existing == null) {
        await AppDb.i.addMember(m);
      } else {
        await AppDb.i.updateMember(m);
      }
      if (!mounted) return;
      snack(
        context,
        existing == null
            ? '${m.name} added successfully'
            : '${m.name} updated successfully',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) snack(context, 'Could not save member: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _genderBtn(String g) {
    final sel = gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = g),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? orange : fieldBg,
            border: Border.all(color: sel ? orange : lineGrey),
            borderRadius: g == 'Male'
                ? const BorderRadius.horizontal(left: Radius.circular(12))
                : g == 'Other'
                ? const BorderRadius.horizontal(right: Radius.circular(12))
                : BorderRadius.zero,
          ),
          child: Text(
            g,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: sel ? ink : muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _planTile(PlanOption p, double w) {
    final sel =
        durationValue == p.durationValue && durationUnit == p.durationUnit;
    return SizedBox(
      width: w,
      child: GestureDetector(
        onTap: () => pickPlan(p),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: sel ? orangeSoft : fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? orange : lineGrey,
              width: sel ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(p.sub, style: const TextStyle(color: muted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exp = expiry;
    final span = exp.difference(dayOnly(join)).inDays;
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PageHeader(
                widget.member == null ? 'Add New Member' : 'Edit Member',
                subtitle: widget.member == null
                    ? 'Enroll athlete into member database'
                    : 'Update member details',
              ),
              Expanded(
                child: TopSheet(
                  child: Form(
                    key: form,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            children: [
                              const FieldLabel('Profile Photo'),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: pickPhoto,
                                  child: photo != null
                                      ? CircleAvatar(
                                          radius: 52,
                                          backgroundImage: MemoryImage(photo!),
                                        )
                                      : DashedBox(
                                          width: 104,
                                          height: 104,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.photo_camera_outlined,
                                                size: 30,
                                                color: ink,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Add Photo',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              Text(
                                                '(Optional)',
                                                style: TextStyle(
                                                  color: muted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              const FieldLabel(
                                'Full Legal Name',
                                required: true,
                              ),
                              TextFormField(
                                controller: name,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                                decoration: fieldDeco(
                                  hint: 'Enter member name',
                                  icon: Icons.person_outline,
                                ),
                              ),
                              const FieldLabel('Phone Number'),
                              TextFormField(
                                controller: phone,
                                keyboardType: TextInputType.phone,
                                decoration: fieldDeco(
                                  hint: 'Optional',
                                  icon: Icons.phone_outlined,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const FieldLabel('Age', required: true),
                                        TextFormField(
                                          controller: age,
                                          keyboardType: TextInputType.number,
                                          validator: (v) {
                                            final n = int.tryParse(
                                              (v ?? '').trim(),
                                            );
                                            return (n == null ||
                                                    n < 5 ||
                                                    n > 100)
                                                ? 'Invalid'
                                                : null;
                                          },
                                          decoration: fieldDeco(
                                            icon: Icons.cake_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 7,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const FieldLabel(
                                          'Gender',
                                          required: true,
                                        ),
                                        Row(
                                          children: [
                                            _genderBtn('Male'),
                                            _genderBtn('Female'),
                                            _genderBtn('Other'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 7,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: 'Treatment Plan',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: ' *',
                                              style: TextStyle(color: warnRed),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: viewPlans,
                                      child: const Text(
                                        'View Plans',
                                        style: TextStyle(
                                          color: orange,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              LayoutBuilder(
                                builder: (c, box) {
                                  final w = (box.maxWidth - 18) / 4;
                                  return Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final p in plans) _planTile(p, w),
                                    ],
                                  );
                                },
                              ),
                              const FieldLabel('Custom Duration'),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: duration,
                                      keyboardType: TextInputType.number,
                                      onChanged: onCustom,
                                      validator: (v) {
                                        final n = int.tryParse((v ?? '').trim());
                                        return (n == null ||
                                                n < 1 ||
                                                n > 1200)
                                            ? 'Enter 1-1200'
                                            : null;
                                      },
                                      decoration: fieldDeco(
                                        icon: Icons.schedule,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<
                                      PlanDurationUnit
                                    >(
                                      key: ValueKey(durationUnit),
                                      initialValue: durationUnit,
                                      decoration: fieldDeco(hint: 'Unit'),
                                      items: PlanDurationUnit.values
                                          .map(
                                            (unit) => DropdownMenuItem(
                                              value: unit,
                                              child: Text(
                                                durationUnitLabel(unit),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (unit) {
                                        if (unit == null) return;
                                        setState(() {
                                          durationUnit = unit;
                                          onCustom(duration.text);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const FieldLabel(
                                'Fee Amount (₹)',
                                required: true,
                              ),
                              TextFormField(
                                controller: fee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) {
                                  final n = double.tryParse((v ?? '').trim());
                                  return (n == null || n < 0)
                                      ? 'Invalid amount'
                                      : null;
                                },
                                decoration: fieldDeco(
                                  icon: Icons.currency_rupee_rounded,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const FieldLabel(
                                          'Joining Date',
                                          required: true,
                                        ),
                                        InkWell(
                                          onTap: pickDate,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            height: 52,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: fieldBg,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: lineGrey,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 20,
                                                  color: muted,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  DateFormat('dd-MM-yyyy')
                                                      .format(join),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const FieldLabel('Calculated Expiry'),
                                        Container(
                                          height: 52,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: okSoft,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xffbfe8cd),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.event_available_outlined,
                                                size: 20,
                                                color: okGreen,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      DateFormat('dd MMM yyyy')
                                                          .format(exp),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: okGreen,
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                    Text(
                                                      '($span Days)',
                                                      style: const TextStyle(
                                                        color: okGreen,
                                                        fontSize: 11.5,
                                                      ),
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
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 7,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: 'Keycard / RFID ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '(Optional)',
                                              style: TextStyle(
                                                color: muted,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: autoAssign,
                                      child: const Text(
                                        'Auto Assign',
                                        style: TextStyle(
                                          color: orange,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextFormField(
                                controller: keycard,
                                decoration: fieldDeco(
                                  hint: 'Tap card or enter ID',
                                  icon: Icons.credit_card_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                          child: PrimaryButton(
                            widget.member == null
                                ? 'Save Patient'
                                : 'Update Member',
                            icon: Icons.arrow_forward_rounded,
                            busy: saving,
                            onPressed: save,
                          ),
                        ),
                      ],
                    ),
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
