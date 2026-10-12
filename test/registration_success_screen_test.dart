import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/features/auth/ui/registration_success_screen.dart';

void main() {
  testWidgets('shows animated registration success and returns to login', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const RegistrationSuccessScreen(),
                    ),
                  );
                },
                child: const Text('Open success screen'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open success screen'));
    await tester.pumpAndSettle();

    expect(find.text('You’re all set!'), findsOneWidget);
    expect(find.text('Workspace ready'), findsOneWidget);
    expect(find.text('Continue to login'), findsOneWidget);

    await tester.tap(find.text('Continue to login'));
    await tester.pumpAndSettle();

    expect(find.text('Open success screen'), findsOneWidget);
  });
}
