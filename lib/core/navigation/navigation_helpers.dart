import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void popOrGo(BuildContext context, String fallbackLocation) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackLocation);
  }
}
