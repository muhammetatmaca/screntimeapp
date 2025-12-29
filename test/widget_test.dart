import 'package:flutter_test/flutter_test.dart';
import 'package:spent_time_focus/main.dart';

void main() {
  testWidgets('App should load onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SpentApp());
    
    // Verify onboarding screen is displayed
    expect(find.text('SPENT'), findsOneWidget);
    expect(find.text('Atla'), findsOneWidget);
  });
}
