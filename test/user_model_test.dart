import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/features/auth/data/user_model.dart';

void main() {
  test('parses API users without a companyId', () {
    final user = User.fromJson({
      'id': 7,
      'email': 'deneesh@gmail.com',
      'name': 'deneesh',
      'role': 'employee',
      'isActive': true,
      'createdAt': '2026-10-01T09:34:44.058Z',
    });

    expect(user.id, 7);
    expect(user.companyId, isNull);
    expect(user.createdAt, DateTime.parse('2026-10-01T09:34:44.058Z'));
  });
}