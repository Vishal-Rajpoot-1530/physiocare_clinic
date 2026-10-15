import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/member.dart';
import 'local_db.dart';

enum AccountMode { online, offline }

class AppDb {
  AppDb._();
  static final i = AppDb._();

  final tick = ValueNotifier<int>(0);
  void notifyChanged() => tick.value++;

  String get baseUrl => ApiConfig.baseUrl;

  Future<AccountMode?> get accountMode async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString('account_mode') ??
        prefs.getString('last_account_mode')) {
      'online' => AccountMode.online,
      'offline' => AccountMode.offline,
      _ => null,
    };
  }

  bool get _offline => _selectedMode == AccountMode.offline;
  AccountMode _selectedMode = AccountMode.online;

  Future<dynamic> _get(String path) {
    if (_offline) throw StateError('API access is disabled for offline mode.');
    return ApiClient.i.get(path);
  }

  Future<dynamic> _send(String method, String path, [Object? body]) {
    if (_offline) throw StateError('API access is disabled for offline mode.');
    return ApiClient.i.request(method, path, body: body);
  }

  Map<String, Object?> _map(dynamic value) =>
      Map<String, Object?>.from(value as Map);

  Map<String, Object?> _memberMap(dynamic value) {
    final member = _map(value);
    final photo = member['photo'];
    if (photo is String && photo.isNotEmpty) {
      member['photo'] = base64Decode(photo);
    } else if (photo is! Uint8List) {
      member['photo'] = null;
    }
    return member;
  }

  Future<void> _saveSession(
    AccountMode mode, {
    required bool remember,
    int? offlineAdminId,
    String? token,
    String? adminName,
  }) async {
    _selectedMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_mode', mode.name);
    await prefs.setString('last_account_mode', mode.name);
    await prefs.setBool('login', remember);
    await prefs.remove('demo_session');
    if (mode == AccountMode.offline) {
      await prefs.remove('api_token');
      if (offlineAdminId == null) {
        throw StateError('Offline account ID is required.');
      }
      await prefs.setInt('offline_admin_id', offlineAdminId);
    } else {
      await prefs.remove('offline_admin_id');
      if (token == null || token.isEmpty) {
        throw StateError('The server did not return an access token.');
      }
      await prefs.setString('api_token', token);
    }
    if (adminName != null) await prefs.setString('admin_name', adminName);
  }

  Future<Map<String, Object?>?> register(
    String name,
    String email,
    String password,
    AccountMode mode, {
    bool remember = true,
  }) async {
    _selectedMode = mode;
    if (mode == AccountMode.offline) {
      final id = await LocalDb.i.register(name, email, password);
      await _saveSession(
        mode,
        remember: remember,
        offlineAdminId: id,
        adminName: name.trim(),
      );
      return {
        'id': id,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
      };
    }

    await _send('POST', '/auth/register', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    return login(email, password, mode, remember: remember);
  }

  Future<Map<String, Object?>?> login(
    String email,
    String password,
    AccountMode mode, {
    bool remember = true,
  }) async {
    _selectedMode = mode;
    if (mode == AccountMode.offline) {
      final admin = await LocalDb.i.login(email, password);
      if (admin == null) return null;
      await _saveSession(
        mode,
        remember: remember,
        offlineAdminId: (admin['id'] as num).toInt(),
        adminName: admin['name'] as String?,
      );
      return admin;
    }

    final data = _map(
      await _send('POST', '/auth/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    final user = _map(data['user']);
    await _saveSession(
      mode,
      remember: remember,
      token: data['token'] as String?,
      adminName: user['name'] as String?,
    );
    return user;
  }

  Future<void> activateLegacyDemoSession() async {
    const email = 'demo@gmail.com';
    const password = '123456';
    var admin = await LocalDb.i.login(email, password);
    if (admin == null) {
      final id = await LocalDb.i.register('Demo User', email, password);
      admin = {'id': id, 'name': 'Demo User', 'email': email};
    }
    await _saveSession(
      AccountMode.offline,
      remember: true,
      offlineAdminId: (admin['id'] as num).toInt(),
      adminName: 'Demo User',
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('admin_name');
    await prefs.remove('demo_session');
    await prefs.remove('account_mode');
    await prefs.remove('offline_admin_id');
    await prefs.setBool('login', false);
    _selectedMode = AccountMode.online;
  }

  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('demo_session') == true) {
      await activateLegacyDemoSession();
      return true;
    }
    final mode = await accountMode;
    final token = prefs.getString('api_token') ?? '';
    if (mode == null && token.isNotEmpty) {
      _selectedMode = AccountMode.online;
      await prefs.setString('account_mode', AccountMode.online.name);
      await prefs.setString('last_account_mode', AccountMode.online.name);
      await prefs.setBool('login', true);
      return true;
    }
    if (prefs.getBool('login') != true) return false;
    if (mode == AccountMode.offline) {
      _selectedMode = mode!;
      return prefs.getInt('offline_admin_id') != null;
    }
    if (mode == AccountMode.online) {
      _selectedMode = mode!;
      return token.isNotEmpty;
    }
    return false;
  }

  Future<Map<String, Object?>> currentAdmin() async {
    if (_offline) {
      final admin = await LocalDb.i.currentAdmin();
      if (admin == null) throw StateError('Offline account was not found.');
      return admin;
    }
    return _map(await _get('/auth/profile'));
  }

  Future<void> updateAdminName(String name) async {
    late String savedName;
    if (_offline) {
      await LocalDb.i.updateAdminName(name);
      savedName = name.trim();
    } else {
      final admin = _map(
        await _send('PATCH', '/auth/profile', {'name': name.trim()}),
      );
      savedName = (admin['name'] as String?) ?? name.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_name', savedName);
    notifyChanged();
  }

  Future<void> changeAdminPassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_offline) {
      await LocalDb.i.changeAdminPassword(currentPassword, newPassword);
      return;
    }
    await _send('PUT', '/auth/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<List<Member>> members() async {
    if (_offline) return LocalDb.i.members();
    return ((await _get('/members')) as List)
        .map((value) => Member.fromMap(_memberMap(value)))
        .toList();
  }

  Future<Member?> member(int id) async {
    if (_offline) return LocalDb.i.member(id);
    try {
      return Member.fromMap(_memberMap(await _get('/members/$id')));
    } catch (_) {
      return null;
    }
  }

  Future<bool> keycardTaken(String code, {int? exceptMemberId}) async {
    if (code.trim().isEmpty) return false;
    if (_offline) {
      return LocalDb.i.keycardTaken(code, exceptMemberId: exceptMemberId);
    }
    final query =
        '?code=${Uri.encodeQueryComponent(code.trim())}${exceptMemberId == null ? '' : '&except=$exceptMemberId'}';
    return (await _get('/members/keycard/check$query'))['taken'] == true;
  }

  Map<String, Object?> _memberBody(Member member) {
    final body = member.toMap()
      ..remove('id')
      ..remove('photo')
      ..remove('duration_months');
    return body;
  }

  Future<int> addMember(Member member, {String method = 'Cash'}) async {
    if (_offline) {
      final id = await LocalDb.i.addMember(member, method: method);
      notifyChanged();
      return id;
    }
    final body = _memberBody(member)..['method'] = method;
    final result = await _send('POST', '/members', body);
    final id = (result['id'] as num).toInt();
    if (member.photo != null && member.photo!.isNotEmpty) {
      await setPhoto(id, member.photo!);
    }
    notifyChanged();
    return id;
  }

  Future<void> updateMember(Member member) async {
    if (member.id == null) throw ArgumentError('Member ID required');
    if (_offline) {
      await LocalDb.i.updateMember(member);
    } else {
      await _send('PUT', '/members/${member.id}', _memberBody(member));
    }
    notifyChanged();
  }

  Future<void> renew(
    Member member,
    String plan,
    int durationValue,
    PlanDurationUnit durationUnit,
    double amount, {
    String method = 'Cash',
  }) async {
    if (_offline) {
      await LocalDb.i.renew(
        member,
        plan,
        durationValue,
        durationUnit,
        amount,
        method: method,
      );
    } else {
      await _send('POST', '/members/${member.id}/renew', {
        'plan': plan,
        'duration_value': durationValue,
        'duration_unit': durationUnit.name.toUpperCase(),
        'amount': amount,
        'method': method,
      });
    }
    notifyChanged();
  }

  Future<void> addAdjustment(
    Member member,
    double amount,
    String note, {
    String method = 'Cash',
  }) async {
    if (_offline) {
      await LocalDb.i.addAdjustment(member, amount, note, method: method);
    } else {
      await _send('POST', '/members/${member.id}/adjustment', {
        'amount': amount,
        'note': note,
        'method': method,
      });
    }
    notifyChanged();
  }

  Future<void> setStatus(int id, bool active) async {
    if (_offline) {
      await LocalDb.i.setStatus(id, active);
    } else {
      await _send('PATCH', '/members/$id/status', {'active': active});
    }
    notifyChanged();
  }

  Future<void> setPr(int id, double kg) async {
    if (_offline) {
      await LocalDb.i.setPr(id, kg);
    } else {
      await _send('PATCH', '/members/$id/pr', {'kg': kg});
    }
    notifyChanged();
  }

  Future<void> setPhoto(int id, Uint8List bytes) async {
    if (_offline) {
      await LocalDb.i.setPhoto(id, bytes);
    } else {
      await ApiClient.i.uploadBytes(
        '/members/$id/photo',
        'photo',
        bytes,
        filename: 'member_$id.jpg',
      );
    }
    notifyChanged();
  }

  Future<void> deleteMember(int id) async {
    if (_offline) {
      await LocalDb.i.deleteMember(id);
    } else {
      await _send('DELETE', '/members/$id');
    }
    notifyChanged();
  }

  Future<int> cleanInactive() async {
    late int deleted;
    if (_offline) {
      deleted = await LocalDb.i.cleanInactive();
    } else {
      final result = await _send('DELETE', '/members/inactive/clean');
      deleted = (result['deleted'] as num).toInt();
    }
    notifyChanged();
    return deleted;
  }

  Future<List<Payment>> payments() async {
    if (_offline) return LocalDb.i.payments();
    return ((await _get('/finance')) as List)
        .map((value) => Payment.fromMap(_map(value)))
        .toList();
  }

  Future<List<Payment>> paymentsFor(int memberId) async {
    if (_offline) return LocalDb.i.payments(memberId: memberId);
    return ((await _get('/finance?member_id=$memberId')) as List)
        .map((value) => Payment.fromMap(_map(value)))
        .toList();
  }

  Future<double> goal() async {
    if (_offline) return LocalDb.i.goal();
    return ((_map(await _get('/settings'))['revenue_goal']) as num).toDouble();
  }

  Future<void> setGoal(double value) async {
    if (_offline) {
      await LocalDb.i.setGoal(value);
    } else {
      await _send('PUT', '/settings/goal', {'value': value});
    }
    notifyChanged();
  }

  Future<List<PlanOption>> plans() async {
    if (_offline) return LocalDb.i.plans();
    final result = _map(await _get('/settings'));
    return (result['plans'] as List)
        .map(
          (value) => PlanOption.of(
            (value['duration_value'] as num?)?.toInt() ??
                (value['months'] as num).toInt(),
            switch ((value['duration_unit'] as String?)?.toLowerCase()) {
              'day' => PlanDurationUnit.day,
              'week' => PlanDurationUnit.week,
              _ => PlanDurationUnit.month,
            },
            (value['fee'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> setPlans(List<PlanOption> plans) async {
    if (_offline) {
      await LocalDb.i.setPlans(plans);
    } else {
      await _send('PUT', '/settings/plans', {
        'plans': plans
            .map(
              (plan) => {
                'duration_value': plan.durationValue,
                'duration_unit': plan.durationUnit.name.toUpperCase(),
                'fee': plan.fee,
              },
            )
            .toList(),
      });
    }
    notifyChanged();
  }

  Future<List<Note>> notesFor(int memberId) async {
    if (_offline) return LocalDb.i.notesFor(memberId);
    return ((await _get('/members/$memberId/notes')) as List)
        .map((value) => Note.fromMap(_map(value)))
        .toList();
  }

  Future<void> addNote(
    int memberId,
    String title,
    String body,
    String tags,
  ) async {
    if (_offline) {
      await LocalDb.i.addNote(memberId, title, body, tags);
    } else {
      await _send('POST', '/members/$memberId/notes', {
        'title': title,
        'body': body,
        'tags': tags,
      });
    }
    notifyChanged();
  }

  Future<Member?> findByCode(String raw) async {
    if (_offline) return LocalDb.i.findByCode(raw);
    final result = await _get(
      '/checkins/find?code=${Uri.encodeQueryComponent(raw.trim())}',
    );
    return result == null ? null : Member.fromMap(_memberMap(result));
  }

  Future<bool> checkIn(int memberId) async {
    late bool created;
    if (_offline) {
      created = await LocalDb.i.checkIn(memberId);
    } else {
      final result = await _send('POST', '/checkins/$memberId');
      created = result['created'] == true;
    }
    notifyChanged();
    return created;
  }

  Future<({int total, int streak})> checkinStats(int memberId) async {
    if (_offline) return LocalDb.i.checkinStats(memberId);
    final result = _map(await _get('/checkins/$memberId/stats'));
    return (
      total: (result['total'] as num).toInt(),
      streak: (result['streak'] as num).toInt(),
    );
  }

  Future<List<Map<String, Object?>>> todayCheckins() async {
    if (_offline) return LocalDb.i.todayCheckins();
    return ((await _get('/checkins/today/list')) as List)
        .map((value) => _map(value))
        .toList();
  }
}
