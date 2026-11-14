import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/progress_provider.dart';
import 'providers/settings_provider.dart';
import 'services/progress/progress_repository.dart';
import 'services/settings/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final progress = await ProgressRepository.open();
  final settings = await SettingsRepository.open();
  runApp(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(progress),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: const AcertaApp(),
    ),
  );
}
