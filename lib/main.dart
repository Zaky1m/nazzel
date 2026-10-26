import 'package:flutter/material.dart';

import 'app.dart';
import 'ui/share_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NazzelApp());
}

// Entry point of ShareActivity, the quality sheet shown over the app that shared the link.
@pragma('vm:entry-point')
void shareMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShareApp());
}
