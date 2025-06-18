import 'package:template/src/design_system/responsive_values.dart';

extension BoolUtils on bool {
  T? condition<T>({
    T Function()? t,
    T Function()? f,
  }) =>
      conditionalValue(
        condition: this,
        ifTrue: t,
        ifFalse: f,
      );
}
