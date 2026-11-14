import 'package:flutter/material.dart';

import '../../build_info.dart';
import '../../data_credit.dart';

/// The app name, its version, where the source is and the data credit.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('acerta', style: theme.textTheme.headlineMedium),
          Text(
            appVersionLabel,
            key: const Key('about-version'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const Text('Source code'),
          const SelectableText(sourceRepoUrl, key: Key('about-source')),
          const SizedBox(height: 16),
          const Text('Data'),
          const SelectableText(dataCredit, key: Key('about-credit')),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const Key('about-licenses'),
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'acerta',
                applicationVersion: appVersionLabel,
              ),
              child: const Text('Open-source licenses'),
            ),
          ),
        ],
      ),
    );
  }
}
