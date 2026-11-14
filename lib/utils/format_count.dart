/// [count] with a comma between thousands, such as `1,893`.
String formatCount(int count) {
  final digits = count.abs().toString();
  final buffer = StringBuffer(count < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// [count] and the word `word` or `words`, such as `1,893 words`.
String formatWords(int count) =>
    '${formatCount(count)} ${count == 1 ? 'word' : 'words'}';
