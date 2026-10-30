import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiocare_clinic/api/api_config.dart';

void main() {
  test('Android emulator defaults to the host machine API', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(ApiConfig.baseUrl, 'http://10.0.2.2:3002/api/v1');
  });

  test('Physio API URLs always target the Physio service', () {
    expect(
      ApiConfig.normalizeBaseUrl('http://10.0.2.2:3001/api/v1'),
      'http://10.0.2.2:3002/api/v1',
    );
    expect(
      ApiConfig.normalizeBaseUrl('http://localhost:3004/api/v1/physio'),
      'http://localhost:3002/api/v1',
    );
  });
}
