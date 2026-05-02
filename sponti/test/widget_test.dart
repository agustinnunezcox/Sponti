import 'package:flutter_test/flutter_test.dart';

import 'package:sponti/models/plan.dart';

void main() {
  test('PlanCategory.fromString defaults safely', () {
    expect(PlanCategory.fromString('music'), PlanCategory.music);
    expect(PlanCategory.fromString('unknown_category'), PlanCategory.culture);
  });
}
