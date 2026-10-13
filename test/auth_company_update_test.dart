import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/core/api/api_client.dart';
import 'package:task_app/features/auth/data/auth_repository.dart';

class _RecordingApiClient extends ApiClient {
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    this.path = path;
    this.body = body;
    return {};
  }
}

void main() {
  test('company updates send the company fields to the update route', () async {
    final api = _RecordingApiClient();
    final repository = AuthRepository(api);

    await repository.updateCompany(
      name: 'Example Co',
      industry: 'Technology',
      website: 'https://example.com',
      companySize: '11-50',
    );

    expect(api.path, '/auth/update/company');
    expect(api.body, {
      'name': 'Example Co',
      'industry': 'Technology',
      'website': 'https://example.com',
      'companySize': '11-50',
    });
  });
}
