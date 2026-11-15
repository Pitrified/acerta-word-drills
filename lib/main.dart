import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data_credit.dart';
import 'providers/learn_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/settings_provider.dart';
import 'services/learn/learn_repository.dart';
import 'services/progress/progress_repository.dart';
import 'services/reports/report_repository.dart';
import 'services/settings/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final progress = await ProgressRepository.open();
  final reports = await ReportRepository.open();
  final learn = await LearnRepository.open();
  final settings = await SettingsRepository.open();
  registerDataLicenses();
  runApp(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(progress),
        reportRepositoryProvider.overrideWithValue(reports),
        learnRepositoryProvider.overrideWithValue(learn),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: const AcertaApp(),
    ),
  );
}
