import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:PyAcademy/main.dart';

void main() {
  testWidgets('Auth screen has email and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());

    expect(
      find.byType(TextField),
      findsNWidgets(2),
    ); 
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);

    expect(find.text('Войти'), findsOneWidget);
  });
}

