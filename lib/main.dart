import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  developer.log('ctOS_TRACE: main() started');
  WidgetsFlutterBinding.ensureInitialized();

  // Set edge-to-edge display
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: CtOSApp(),
    ),
  );
}
