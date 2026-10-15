import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/member.dart';

String _durationLabel(int value, PlanDurationUnit unit) {
  final name = switch (unit) {
    PlanDurationUnit.day => 'day',
    PlanDurationUnit.week => 'week',
    PlanDurationUnit.month => 'month',
  };
  return '$value $name${value == 1 ? '' : 's'}';
}

class LocalDb {
  LocalDb._();

  static final LocalDb i = LocalDb._();
  Database? _database;
  String? _databasePathOverride;

  void setDatabasePathForTesting(String? path) {
    if (_database != null) {
      throw StateError('Database is already open.');
    }
    _databasePathOverride = path;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> get database async {
    if (_database case final db?) return db;
    if (kIsWeb) {
      throw UnsupportedError('Offline SQLite storage is not available on web.');
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final path =
        _databasePathOverride ??
        p.join(await getDatabasesPath(), 'physiocare_offline.db');
    final db = await openDatabase(
      path,
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    _database = db;
    return db;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE admins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE COLLATE NOCASE,
        password_salt TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        plan TEXT NOT NULL,
        duration_months INTEGER NOT NULL,
        duration_value INTEGER NOT NULL,
        duration_unit TEXT NOT NULL DEFAULT 'MONTH',
        fee REAL NOT NULL,
        joining_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT NOT NULL DEFAULT '',
        keycard TEXT,
        pr_kg REAL NOT NULL DEFAULT 0,
        photo BLOB,
        created_at TEXT NOT NULL,
        UNIQUE(admin_id, keycard)
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
        member_id INTEGER REFERENCES members(id) ON DELETE SET NULL,
        member_name TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        plan TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        paid_at TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'Cash'
      )
    ''');
    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
        duration_value INTEGER NOT NULL,
        duration_unit TEXT NOT NULL,
        fee REAL NOT NULL,
        UNIQUE(admin_id, duration_value, duration_unit)
      )
    ''');
    await db.execute('''
      CREATE TABLE local_settings (
        admin_id INTEGER PRIMARY KEY REFERENCES admins(id) ON DELETE CASCADE,
        revenue_goal REAL NOT NULL DEFAULT 18500
      )
    ''');
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
        member_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        body TEXT NOT NULL DEFAULT '',
        tags TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE checkins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
        member_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
        checked_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX checkins_member_date ON checkins(admin_id, member_id, checked_at)',
    );
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE members ADD COLUMN duration_value INTEGER NOT NULL DEFAULT 1",
      );
      await db.execute(
        "ALTER TABLE members ADD COLUMN duration_unit TEXT NOT NULL DEFAULT 'MONTH'",
      );
      await db.execute('UPDATE members SET duration_value = duration_months');
      await db.execute('''
        CREATE TABLE plans_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          admin_id INTEGER NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
          duration_value INTEGER NOT NULL,
          duration_unit TEXT NOT NULL,
          fee REAL NOT NULL,
          UNIQUE(admin_id, duration_value, duration_unit)
        )
      ''');
      await db.execute('''
        INSERT INTO plans_v2 (id, admin_id, duration_value, duration_unit, fee)
        SELECT id, admin_id, months, 'MONTH', fee FROM plans
      ''');
      await db.execute('DROP TABLE plans');
      await db.execute('ALTER TABLE plans_v2 RENAME TO plans');
    }
    if (oldVersion < 3) {
      const legacyPlanSets = [
        {'1:DAY': 150.0, '3:WEEK': 180.0, '6:MONTH': 340.0, '12:MONTH': 620.0},
        {
          '1:MONTH': 65.0,
          '3:MONTH': 180.0,
          '6:MONTH': 340.0,
          '12:MONTH': 620.0,
        },
      ];
      final admins = await db.query(
        'plans',
        distinct: true,
        columns: ['admin_id'],
      );
      for (final admin in admins) {
        final adminId = (admin['admin_id'] as num).toInt();
        final rows = await db.query(
          'plans',
          where: 'admin_id = ?',
          whereArgs: [adminId],
        );
        final storedPlans = {
          for (final row in rows)
            '${row['duration_value']}:${row['duration_unit']}':
                (row['fee'] as num).toDouble(),
        };
        final hasLegacyDefaults = legacyPlanSets.any(
          (legacy) =>
              storedPlans.length == legacy.length &&
              legacy.entries.every(
                (entry) => storedPlans[entry.key] == entry.value,
              ),
        );
        if (!hasLegacyDefaults) continue;

        await db.delete('plans', where: 'admin_id = ?', whereArgs: [adminId]);
        for (final plan in kPlans) {
          await db.insert('plans', {
            'admin_id': adminId,
            'duration_value': plan.durationValue,
            'duration_unit': plan.durationUnit.name.toUpperCase(),
            'fee': plan.fee,
          });
        }
      }
    }
  }

  String _newSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(24, (_) => random.nextInt(256)));
  }

  String _passwordHash(String salt, String password) =>
      _derivePasswordHash(salt, password);

  String _derivePasswordHash(String salt, String password) {
    final key = utf8.encode(password);
    final saltBytes = base64Url.decode(salt);
    final hmac = Hmac(sha256, key);
    var block = hmac.convert([...saltBytes, 0, 0, 0, 1]).bytes;
    final derived = List<int>.of(block);
    for (var i = 1; i < 120000; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < derived.length; j++) {
        derived[j] ^= block[j];
      }
    }
    return base64UrlEncode(derived);
  }

  Future<int> register(String name, String email, String password) async {
    final db = await database;
    final salt = _newSalt();
    final now = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final id = await txn.insert('admins', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password_salt': salt,
        'password_hash': _passwordHash(salt, password),
        'created_at': now,
      });
      await txn.insert('local_settings', {
        'admin_id': id,
        'revenue_goal': 18500,
      });
      for (final plan in kPlans) {
        await txn.insert('plans', {
          'admin_id': id,
          'duration_value': plan.durationValue,
          'duration_unit': plan.durationUnit.name.toUpperCase(),
          'fee': plan.fee,
        });
      }
      return id;
    });
  }

  Future<Map<String, Object?>?> login(String email, String password) async {
    final db = await database;
    final rows = await db.query(
      'admins',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final salt = row['password_salt'] as String;
    if (_passwordHash(salt, password) != row['password_hash']) return null;
    return _adminJson(row);
  }

  Map<String, Object?> _adminJson(Map<String, Object?> row) => {
    'id': row['id'],
    'name': row['name'],
    'email': row['email'],
    'created_at': row['created_at'],
  };

  Future<int> _ownerId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('offline_admin_id');
    if (id == null) throw StateError('No offline account is signed in.');
    return id;
  }

  Future<Map<String, Object?>?> currentAdmin() async {
    final db = await database;
    final rows = await db.query(
      'admins',
      where: 'id = ?',
      whereArgs: [await _ownerId()],
      limit: 1,
    );
    return rows.isEmpty ? null : _adminJson(rows.first);
  }

  Future<void> updateAdminName(String name) async {
    final db = await database;
    await db.update(
      'admins',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [await _ownerId()],
    );
  }

  Future<void> changeAdminPassword(String current, String next) async {
    final db = await database;
    final id = await _ownerId();
    final rows = await db.query('admins', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw StateError('Offline account was not found.');
    final row = rows.first;
    final salt = row['password_salt'] as String;
    if (_passwordHash(salt, current) != row['password_hash']) {
      throw StateError('Current password is incorrect.');
    }
    final nextSalt = _newSalt();
    await db.update(
      'admins',
      {
        'password_salt': nextSalt,
        'password_hash': _passwordHash(nextSalt, next),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Member>> members() async {
    final db = await database;
    final rows = await db.query(
      'members',
      where: 'admin_id = ?',
      whereArgs: [await _ownerId()],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map((row) => Member.fromMap(row)).toList();
  }

  Future<Member?> member(int id) async {
    final db = await database;
    final rows = await db.query(
      'members',
      where: 'admin_id = ? AND id = ?',
      whereArgs: [await _ownerId(), id],
      limit: 1,
    );
    return rows.isEmpty ? null : Member.fromMap(rows.first);
  }

  Future<bool> keycardTaken(String code, {int? exceptMemberId}) async {
    if (code.trim().isEmpty) return false;
    final db = await database;
    final where = exceptMemberId == null
        ? 'admin_id = ? AND keycard = ?'
        : 'admin_id = ? AND keycard = ? AND id != ?';
    final args = exceptMemberId == null
        ? [await _ownerId(), code.trim()]
        : [await _ownerId(), code.trim(), exceptMemberId];
    final rows = await db.query(
      'members',
      columns: ['id'],
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> addMember(Member member, {String method = 'Cash'}) async {
    final db = await database;
    final owner = await _ownerId();
    final map = member.toMap()
      ..remove('id')
      ..['admin_id'] = owner;
    map['duration_months'] = member.durationUnit == PlanDurationUnit.month
        ? member.durationValue
        : 0;
    if (member.keycard.trim().isEmpty) map['keycard'] = null;
    return db.transaction((txn) async {
      final id = await txn.insert('members', map);
      await txn.insert('payments', {
        'admin_id': owner,
        'member_id': id,
        'member_name': member.name,
        'amount': member.fee,
        'type': 'joining',
        'plan': member.plan,
        'description': 'Initial membership payment',
        'paid_at': DateTime.now().toIso8601String(),
        'method': method,
      });
      return id;
    });
  }

  Future<void> updateMember(Member member) async {
    final id = member.id;
    if (id == null) throw ArgumentError('Member ID required');
    final map = member.toMap()
      ..remove('id')
      ..remove('created_at');
    map['duration_months'] = member.durationUnit == PlanDurationUnit.month
        ? member.durationValue
        : 0;
    if (member.keycard.trim().isEmpty) map['keycard'] = null;
    final db = await database;
    await db.update(
      'members',
      map,
      where: 'admin_id = ? AND id = ?',
      whereArgs: [await _ownerId(), id],
    );
  }

  Future<void> renew(
    Member member,
    String plan,
    int durationValue,
    PlanDurationUnit durationUnit,
    double amount, {
    String method = 'Cash',
  }) async {
    final db = await database;
    final owner = await _ownerId();
    final now = DateTime.now();
    final start = member.expiryDate.isAfter(now) ? member.expiryDate : now;
    final expiry = addDuration(start, durationValue, durationUnit);
    await db.transaction((txn) async {
      await txn.update(
        'members',
        {
          'plan': plan,
          'duration_months': durationUnit == PlanDurationUnit.month
              ? durationValue
              : 0,
          'duration_value': durationValue,
          'duration_unit': durationUnit.name.toUpperCase(),
          'fee': amount,
          'expiry_date': expiry.toIso8601String(),
          'status': 'active',
        },
        where: 'admin_id = ? AND id = ?',
        whereArgs: [owner, member.id],
      );
      await txn.insert('payments', {
        'admin_id': owner,
        'member_id': member.id,
        'member_name': member.name,
        'amount': amount,
        'type': 'renewal',
        'plan': plan,
        'description':
            'Membership renewal (${_durationLabel(durationValue, durationUnit)})',
        'paid_at': now.toIso8601String(),
        'method': method,
      });
    });
  }

  Future<void> addAdjustment(
    Member member,
    double amount,
    String note, {
    String method = 'Cash',
  }) async {
    final db = await database;
    await db.insert('payments', {
      'admin_id': await _ownerId(),
      'member_id': member.id,
      'member_name': member.name,
      'amount': amount,
      'type': 'adjustment',
      'plan': member.plan,
      'description': note.isEmpty ? 'Payment adjustment' : note,
      'paid_at': DateTime.now().toIso8601String(),
      'method': method,
    });
  }

  Future<void> setStatus(int id, bool active) async {
    final db = await database;
    await db.update(
      'members',
      {'status': active ? 'active' : 'inactive'},
      where: 'admin_id = ? AND id = ?',
      whereArgs: [await _ownerId(), id],
    );
  }

  Future<void> setPr(int id, double kg) async {
    final db = await database;
    await db.update(
      'members',
      {'pr_kg': kg},
      where: 'admin_id = ? AND id = ?',
      whereArgs: [await _ownerId(), id],
    );
  }

  Future<void> setPhoto(int id, Uint8List bytes) async {
    final db = await database;
    await db.update(
      'members',
      {'photo': bytes},
      where: 'admin_id = ? AND id = ?',
      whereArgs: [await _ownerId(), id],
    );
  }

  Future<void> deleteMember(int id) async {
    final db = await database;
    await db.delete(
      'members',
      where: 'admin_id = ? AND id = ?',
      whereArgs: [await _ownerId(), id],
    );
  }

  Future<int> cleanInactive() async {
    final db = await database;
    return db.delete(
      'members',
      where: "admin_id = ? AND status = 'inactive'",
      whereArgs: [await _ownerId()],
    );
  }

  Future<List<Payment>> payments({int? memberId}) async {
    final db = await database;
    final owner = await _ownerId();
    final rows = await db.query(
      'payments',
      where: memberId == null
          ? 'admin_id = ?'
          : 'admin_id = ? AND member_id = ?',
      whereArgs: memberId == null ? [owner] : [owner, memberId],
      orderBy: 'paid_at DESC, id DESC',
    );
    return rows.map((row) => Payment.fromMap(row)).toList();
  }

  Future<double> goal() async {
    final db = await database;
    final rows = await db.query(
      'local_settings',
      columns: ['revenue_goal'],
      where: 'admin_id = ?',
      whereArgs: [await _ownerId()],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Offline settings were not found.');
    return (rows.first['revenue_goal'] as num).toDouble();
  }

  Future<void> setGoal(double value) async {
    final db = await database;
    await db.update(
      'local_settings',
      {'revenue_goal': value},
      where: 'admin_id = ?',
      whereArgs: [await _ownerId()],
    );
  }

  Future<List<PlanOption>> plans() async {
    final db = await database;
    final rows = await db.query(
      'plans',
      where: 'admin_id = ?',
      whereArgs: [await _ownerId()],
      orderBy: 'duration_unit, duration_value',
    );
    return rows
        .map(
          (row) => PlanOption.of(
            (row['duration_value'] as num).toInt(),
            _planUnit(row['duration_unit'] as String),
            (row['fee'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> setPlans(List<PlanOption> plans) async {
    final db = await database;
    final owner = await _ownerId();
    await db.transaction((txn) async {
      await txn.delete('plans', where: 'admin_id = ?', whereArgs: [owner]);
      for (final plan in plans) {
        await txn.insert('plans', {
          'admin_id': owner,
          'duration_value': plan.durationValue,
          'duration_unit': plan.durationUnit.name.toUpperCase(),
          'fee': plan.fee,
        });
      }
    });
  }

  PlanDurationUnit _planUnit(String value) => switch (value.toLowerCase()) {
    'day' => PlanDurationUnit.day,
    'week' => PlanDurationUnit.week,
    _ => PlanDurationUnit.month,
  };

  Future<List<Note>> notesFor(int memberId) async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where: 'admin_id = ? AND member_id = ?',
      whereArgs: [await _ownerId(), memberId],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => Note.fromMap(row)).toList();
  }

  Future<void> addNote(
    int memberId,
    String title,
    String body,
    String tags,
  ) async {
    final db = await database;
    await db.insert('notes', {
      'admin_id': await _ownerId(),
      'member_id': memberId,
      'title': title,
      'body': body,
      'tags': tags,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Member?> findByCode(String raw) async {
    final search = raw.trim();
    final list = await members();
    for (final member in list) {
      if (member.keycard == search || member.phone == search) return member;
    }
    final match = RegExp(
      r'^(?:mv-?)?0*(\d+)$',
      caseSensitive: false,
    ).firstMatch(search);
    if (match != null) {
      final id = int.tryParse(match.group(1)!);
      for (final member in list) {
        if (member.id == id) return member;
      }
    }
    return null;
  }

  Future<bool> checkIn(int memberId) async {
    final db = await database;
    final owner = await _ownerId();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM checkins WHERE admin_id = ? AND member_id = ? AND checked_at >= ? AND checked_at < ?',
        [
          owner,
          memberId,
          start.toIso8601String(),
          start.add(const Duration(days: 1)).toIso8601String(),
        ],
      ),
    );
    if ((count ?? 0) > 0) return false;
    await db.insert('checkins', {
      'admin_id': owner,
      'member_id': memberId,
      'checked_at': now.toIso8601String(),
    });
    return true;
  }

  Future<({int total, int streak})> checkinStats(int memberId) async {
    final db = await database;
    final rows = await db.query(
      'checkins',
      columns: ['checked_at'],
      where: 'admin_id = ? AND member_id = ?',
      whereArgs: [await _ownerId(), memberId],
      orderBy: 'checked_at DESC',
    );
    final days = rows
        .map((row) => DateTime.parse(row['checked_at'] as String))
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    var current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);
    if (!days.contains(current)) {
      current = current.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    return (total: rows.length, streak: streak);
  }

  Future<List<Map<String, Object?>>> todayCheckins() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return db.rawQuery(
      '''
      SELECT checkins.checked_at AS at, members.name AS name, members.id AS id
      FROM checkins JOIN members ON checkins.member_id = members.id
      WHERE checkins.admin_id = ? AND checkins.checked_at >= ? AND checkins.checked_at < ?
      ORDER BY checkins.checked_at DESC
      ''',
      [
        await _ownerId(),
        start.toIso8601String(),
        start.add(const Duration(days: 1)).toIso8601String(),
      ],
    );
  }
}
