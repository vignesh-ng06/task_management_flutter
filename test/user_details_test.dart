import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_app/core/api/api_client.dart';
import 'package:task_app/features/users/data/user_repository.dart';

void main() {
  test(
    'loads the detail endpoint and parses assigned tasks and projects',
    () async {
      Uri? requestedUri;
      final api = ApiClient(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 4,
                'email': 'priyanka@gmail.com',
                'name': 'priyanka k',
                'role': 'employee',
                'isActive': true,
                'createdAt': '2026-10-01T09:23:44.394Z',
                'updatedAt': '2026-10-09T12:04:42.865Z',
                'projectsCreated': [],
                'tasksAssigned': [
                  {
                    'id': 1,
                    'title': 'Create the crud operation',
                    'status': 'COMPLETED',
                    'priority': 'MEDIUM',
                    'dueDate': '2026-10-15T17:00:00.000Z',
                  },
                  {
                    'id': 3,
                    'title': 'Testing',
                    'status': 'TODO',
                    'priority': 'MEDIUM',
                    'dueDate': '2026-10-19T17:00:00.000Z',
                  },
                ],
                'projects': [
                  {'id': 3, 'name': 'Pawblr'},
                ],
                'projectCount': 1,
              },
            }),
            200,
          );
        }),
      );
      final repository = UserRepository(api);

      final details = await repository.getUserDetails(4);

      expect(requestedUri?.path, endsWith('/users/getUser/4'));
      expect(details.user.displayName, 'priyanka k');
      expect(details.user.projectCount, 1);
      expect(details.projects.single.name, 'Pawblr');
      expect(details.projectsCreated, isEmpty);
      expect(details.tasksAssigned, hasLength(2));
      expect(details.tasksAssigned.last.status, 'TODO');
      expect(details.updatedAt, DateTime.parse('2026-10-09T12:04:42.865Z'));
    },
  );
}
