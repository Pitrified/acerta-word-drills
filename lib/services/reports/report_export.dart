import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/word_report.dart';

/// Writes a text file where the learner chooses.
abstract interface class FileSaver {
  /// Asks the learner for a place and writes [text] to [fileName] there.
  ///
  /// Returns false when the learner cancels the dialog.
  Future<bool> saveText({required String fileName, required String text});
}

/// A [FileSaver] over Android's create document dialog, asked through
/// `MainActivity`.
class ChannelFileSaver implements FileSaver {
  const ChannelFileSaver();

  static const _channel = MethodChannel('acerta/save_file');

  @override
  Future<bool> saveText({
    required String fileName,
    required String text,
  }) async {
    final saved = await _channel.invokeMethod<bool>('saveText', {
      'fileName': fileName,
      'text': text,
    });
    return saved ?? false;
  }
}

/// What the reports file holds and what it is called.
abstract final class ReportExport {
  /// The JSON lines of [reports], one object per line.
  ///
  /// Each object holds the fields of the report in snake_case and the
  /// `app_version` of the build that writes the file.
  static String toJsonLines(
    List<WordReport> reports, {
    required String appVersion,
  }) => reports
      .map((r) => '${jsonEncode({...r.toJson(), 'app_version': appVersion})}\n')
      .join();

  /// The file name for a save at [now], such as
  /// `acerta-reports-20260102-0930.jsonl`.
  static String fileName(DateTime now) {
    String pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');
    return 'acerta-reports-${pad(now.year, 4)}${pad(now.month)}${pad(now.day)}'
        '-${pad(now.hour)}${pad(now.minute)}.jsonl';
  }
}
