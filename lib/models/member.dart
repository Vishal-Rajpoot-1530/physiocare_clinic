import 'dart:typed_data';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds [m] months (can be negative) and clamps the day (31 Jan + 1 month = 28/29 Feb).
DateTime addMonths(DateTime d, int m) {
  final total = d.month - 1 + m;
  final year = d.year + (total - (total % 12)) ~/ 12;
  final month = total % 12 + 1;
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > last ? last : d.day);
}

enum PlanDurationUnit { day, week, month }

String durationUnitLabel(PlanDurationUnit unit) => switch (unit) {
  PlanDurationUnit.day => 'Day',
  PlanDurationUnit.week => 'Week',
  PlanDurationUnit.month => 'Month',
};

DateTime addDuration(DateTime date, int value, PlanDurationUnit unit) =>
    switch (unit) {
      PlanDurationUnit.day => date.add(Duration(days: value)),
      PlanDurationUnit.week => date.add(Duration(days: value * 7)),
      PlanDurationUnit.month => addMonths(date, value),
    };

enum MStatus { active, dueSoon, inactive, expired }

class Member {
  final int? id;
  final String name, email, phone, gender, plan, status, notes, keycard;
  final int age, durationValue;
  final PlanDurationUnit durationUnit;
  final double fee, prKg;
  final DateTime joiningDate, expiryDate, createdAt;
  final Uint8List? photo;

  Member({
    this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    required this.gender,
    required this.age,
    required this.plan,
    required this.durationValue,
    this.durationUnit = PlanDurationUnit.month,
    required this.fee,
    required this.joiningDate,
    required this.expiryDate,
    this.status = 'active',
    this.notes = '',
    this.keycard = '',
    this.prKg = 0,
    this.photo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Days until the plan expires (negative = already expired).
  int get daysLeft =>
      dayOnly(expiryDate).difference(dayOnly(DateTime.now())).inDays;

  bool get lapsed => daysLeft < 0;

  /// Effective state used everywhere in the UI.
  /// Manual inactive status is distinct from a membership that has expired.
  MStatus get state {
    if (daysLeft < 0) return MStatus.expired;
    if (status == 'inactive') return MStatus.inactive;
    if (daysLeft <= 7) return MStatus.dueSoon;
    return MStatus.active;
  }

  String get code => 'MV-${(id ?? 0).toString().padLeft(4, '0')}';

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'gender': gender,
    'age': age,
    'plan': plan,
    'duration_value': durationValue,
    'duration_unit': durationUnit.name.toUpperCase(),
    'duration_months': durationUnit == PlanDurationUnit.month
        ? durationValue
        : 0,
    'fee': fee,
    'joining_date': joiningDate.toIso8601String(),
    'expiry_date': expiryDate.toIso8601String(),
    'status': status,
    'notes': notes,
    'keycard': keycard,
    'pr_kg': prKg,
    'photo': photo,
    'created_at': createdAt.toIso8601String(),
  };

  factory Member.fromMap(Map<String, Object?> m) {
    final legacyMonths = (m['duration_months'] as num?)?.toInt() ?? 1;
    final value = (m['duration_value'] as num?)?.toInt() ?? legacyMonths;
    final unitName = (m['duration_unit'] as String?)?.toLowerCase();
    final unit = switch (unitName) {
      'day' => PlanDurationUnit.day,
      'week' => PlanDurationUnit.week,
      _ => PlanDurationUnit.month,
    };
    return Member(
      id: m['id'] as int?,
      name: (m['name'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      phone: (m['phone'] as String?) ?? '',
      gender: (m['gender'] as String?) ?? 'Male',
      age: (m['age'] as num?)?.toInt() ?? 0,
      plan: (m['plan'] as String?) ?? '',
      durationValue: value,
      durationUnit: unit,
      fee: (m['fee'] as num?)?.toDouble() ?? 0,
      joiningDate: DateTime.parse(m['joining_date'] as String),
      expiryDate: DateTime.parse(m['expiry_date'] as String),
      status: (m['status'] as String?) ?? 'active',
      notes: (m['notes'] as String?) ?? '',
      keycard: (m['keycard'] as String?) ?? '',
      prKg: (m['pr_kg'] as num?)?.toDouble() ?? 0,
      photo: m['photo'] as Uint8List?,
      createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
    );
  }
}

class Payment {
  final int id;
  final int? memberId;
  final String memberName, type, plan, description, method;
  final double amount;
  final DateTime paidAt;

  const Payment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.type,
    required this.plan,
    required this.description,
    required this.method,
    required this.amount,
    required this.paidAt,
  });

  factory Payment.fromMap(Map<String, Object?> m) => Payment(
    id: (m['id'] as num).toInt(),
    memberId: (m['member_id'] as num?)?.toInt(),
    memberName: (m['member_name'] as String?) ?? '',
    type: (m['type'] as String?) ?? 'joining',
    plan: (m['plan'] as String?) ?? '',
    description: (m['description'] as String?) ?? '',
    method: (m['method'] as String?) ?? 'Cash',
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
    paidAt: DateTime.parse(m['paid_at'] as String),
  );
}

class Note {
  final int id, memberId;
  final String title, body, tags;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.memberId,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
  });

  List<String> get tagList =>
      tags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  factory Note.fromMap(Map<String, Object?> m) => Note(
    id: (m['id'] as num).toInt(),
    memberId: (m['member_id'] as num).toInt(),
    title: (m['title'] as String?) ?? '',
    body: (m['body'] as String?) ?? '',
    tags: (m['tags'] as String?) ?? '',
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class PlanOption {
  final String sub;
  final int durationValue;
  final PlanDurationUnit durationUnit;
  final double fee;
  const PlanOption(this.durationValue, this.durationUnit, this.fee, this.sub);

  String get label {
    final unit = durationUnitLabel(durationUnit);
    final plural = durationValue == 1 ? unit : '${unit}s';
    return '$durationValue $plural';
  }

  factory PlanOption.of(
    int durationValue,
    PlanDurationUnit durationUnit,
    double fee,
  ) {
    String sub;
    if (durationUnit == PlanDurationUnit.day) {
      sub = 'Daily';
    } else if (durationUnit == PlanDurationUnit.week) {
      sub = 'Weekly';
    } else {
      sub = switch (durationValue) {
        1 => 'Standard',
        3 => 'Quarterly',
        6 => 'Semi-Annual',
        12 => 'Annual',
        _ => 'Custom',
      };
    }
    return PlanOption(durationValue, durationUnit, fee, sub);
  }
}

const List<PlanOption> kPlans = [
  PlanOption(1, PlanDurationUnit.day, 400, 'Daily'),
  PlanOption(1, PlanDurationUnit.week, 2500, 'Weekly'),
  PlanOption(1, PlanDurationUnit.month, 10000, 'Standard'),
  PlanOption(3, PlanDurationUnit.month, 25000, 'Quarterly'),
];
