import 'package:flutter_test/flutter_test.dart';

import 'package:coffee_record/main.dart';

void main() {
  testWidgets('App should display home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CoffeeRecordApp());

    // 应该显示标题
    expect(find.text('手冲咖啡记录'), findsOneWidget);

    // 应该显示空状态
    expect(find.text('还没有冲煮记录'), findsOneWidget);
    expect(find.text('记录冲煮'), findsOneWidget);
  });
}
