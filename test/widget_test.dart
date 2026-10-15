import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:physiocare_clinic/db/app_db.dart';
import 'package:physiocare_clinic/db/local_db.dart';
import 'package:physiocare_clinic/models/member.dart';
import 'package:physiocare_clinic/widgets/live.dart';

void main() {
  test('addMonths clamps to the end of shorter months', () {
    expect(addMonths(DateTime(2025, 1, 31), 1), DateTime(2025, 2, 28));
    expect(addMonths(DateTime(2025, 10, 24), 1), DateTime(2025, 11, 24));
    expect(addMonths(DateTime(2025, 11, 30), 3), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2025, 1, 15), -2), DateTime(2024, 11, 15));
  });

  test(
    'day, week, and month membership durations calculate expiry correctly',
    () {
      expect(
        addDuration(DateTime(2025, 1, 31), 1, PlanDurationUnit.day),
        DateTime(2025, 2, 1),
      );
      expect(
        addDuration(DateTime(2025, 1, 31), 2, PlanDurationUnit.week),
        DateTime(2025, 2, 14),
      );
      expect(
        addDuration(DateTime(2025, 1, 31), 1, PlanDurationUnit.month),
        DateTime(2025, 2, 28),
      );
    },
  );

  test('default membership plans use the requested durations and fees', () {
    expect(
      kPlans.map((plan) => (plan.durationValue, plan.durationUnit, plan.fee)),
      [
        (1, PlanDurationUnit.day, 400.0),
        (1, PlanDurationUnit.week, 2500.0),
        (1, PlanDurationUnit.month, 10000.0),
        (3, PlanDurationUnit.month, 25000.0),
      ],
    );
  });

  test('member state reflects expiry', () {
    Member make(int daysFromNow, {String status = 'active'}) => Member(
      name: 'Test User',
      gender: 'Male',
      age: 25,
      plan: '1 Month',
      durationValue: 1,
      durationUnit: PlanDurationUnit.month,
      fee: 65,
      joiningDate: DateTime.now(),
      expiryDate: DateTime.now().add(Duration(days: daysFromNow)),
      status: status,
    );
    expect(make(30).state, MStatus.active);
    expect(make(3).state, MStatus.dueSoon);
    expect(make(-2).state, MStatus.expired);
    expect(make(30, status: 'inactive').state, MStatus.inactive);
    expect(make(6, status: 'active').state, MStatus.dueSoon);
    expect(make(-2, status: 'inactive').state, MStatus.expired);
  });

  testWidgets('Live keeps fallback UI visible when data cannot load', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Live<List<String>>(
            load: () async => throw StateError('API unavailable'),
            fallbackData: const [],
            builder: (context, data) => ListView(
              children: [
                const Text('Screen content stays visible'),
                if (data.isEmpty) const Text('Empty state'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Screen content stays visible'), findsOneWidget);
    expect(find.text('Empty state'), findsOneWidget);
    expect(
      find.textContaining('Data unavailable: API unavailable'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('offline account and clinic records stay in local SQLite', () async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final directory = await Directory.systemTemp.createTemp(
      'physiocare-offline-test-',
    );
    final databaseFile = '${directory.path}${Platform.pathSeparator}test.db';
    LocalDb.i.setDatabasePathForTesting(databaseFile);
    addTearDown(() async {
      await LocalDb.i.close();
      LocalDb.i.setDatabasePathForTesting(null);
      await directory.delete(recursive: true);
    });

    final account = await AppDb.i.register(
      'Offline User',
      'offline@example.com',
      'password123',
      AccountMode.offline,
    );
    expect(account?['name'], 'Offline User');
    expect(await AppDb.i.accountMode, AccountMode.offline);
    expect(await AppDb.i.hasSession(), isTrue);
    expect((await AppDb.i.currentAdmin())['email'], 'offline@example.com');
    expect(await AppDb.i.members(), isEmpty);
    expect(
      await AppDb.i.login(
        'offline@example.com',
        'password123',
        AccountMode.offline,
      ),
      isNotNull,
    );

    final memberId = await AppDb.i.addMember(
      Member(
        name: 'Local Patient',
        gender: 'Other',
        age: 31,
        plan: '1 Month',
        durationValue: 1,
        durationUnit: PlanDurationUnit.month,
        fee: 65,
        joiningDate: DateTime(2026, 10, 1),
        expiryDate: DateTime(2026, 11, 1),
      ),
    );
    expect((await AppDb.i.members()).single.id, memberId);
    expect((await AppDb.i.payments()).single.memberName, 'Local Patient');
    expect(await AppDb.i.checkIn(memberId), isTrue);
    expect(await AppDb.i.checkIn(memberId), isFalse);
    expect((await AppDb.i.todayCheckins()).single['name'], 'Local Patient');

    await AppDb.i.activateLegacyDemoSession();
    expect(await AppDb.i.accountMode, AccountMode.offline);
    expect(
      await AppDb.i.currentAdmin().then((admin) => admin['email']),
      'demo@gmail.com',
    );
    expect(
      (await SharedPreferences.getInstance()).getString('api_token'),
      isNull,
    );
  });
}
