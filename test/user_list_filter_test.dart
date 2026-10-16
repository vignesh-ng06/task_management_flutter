import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_app/core/api/api_client.dart';
import 'package:task_app/features/users/bloc/user_bloc.dart';
import 'package:task_app/features/users/bloc/user_event.dart';
import 'package:task_app/features/users/bloc/user_state.dart';
import 'package:task_app/features/users/data/user_repository.dart';

void main() {
  test('active and inactive tabs request their matching user lists', () async {
    final requestedUris = <Uri>[];
    final api = ApiClient(
      client: MockClient((request) async {
        requestedUris.add(request.url);
        return http.Response(jsonEncode({'data': []}), 200);
      }),
    );
    final bloc = UserBloc(UserRepository(api));
    addTearDown(bloc.close);

    final activeLoaded = bloc.stream.firstWhere(
      (state) => state.status == UserListStatus.loaded,
    );
    bloc.add(const UsersLoadRequested());
    final activeState = await activeLoaded;

    expect(activeState.includeInactive, isFalse);
    expect(requestedUris.single.queryParameters, isEmpty);

    final inactiveLoaded = bloc.stream.firstWhere(
      (state) => state.status == UserListStatus.loaded && state.includeInactive,
    );
    bloc.add(const UsersLoadRequested(includeInactive: true));
    final inactiveState = await inactiveLoaded;

    expect(inactiveState.includeInactive, isTrue);
    expect(requestedUris.last.queryParameters, {'status': 'inactive'});
  });
}
