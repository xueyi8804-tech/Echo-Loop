import 'dart:io';

import 'package:echo_loop/data/bundled_chinese_translations.dart';
import 'package:echo_loop/services/subtitle_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('六篇内置课程的每一句均有离线中文翻译', () async {
    final files = Directory('assets/demo').listSync().whereType<File>()
        .where((file) => file.path.endsWith('.srt')).toList();
    expect(files, hasLength(6));
    var sentenceCount = 0;
    for (final file in files) {
      final sentences = await SubtitleParser.parseSubtitleStrict(file.path);
      for (final sentence in sentences) {
        expect(bundledChineseTranslation(sentence.text, targetLanguage: 'zh'),
            isNotEmpty, reason: sentence.text);
        sentenceCount++;
      }
    }
    expect(sentenceCount, 40);
  });

  test('未提供的句子和非简体中文目标不返回错误译文', () {
    expect(bundledChineseTranslation('Unknown sentence', targetLanguage: 'zh'), isNull);
    expect(bundledChineseTranslation('Our class is in Room 13 on the 1st Floor.',
        targetLanguage: 'en'), isNull);
    expect(bundledChineseTranslation('Our class is in Room 13 on the 1st Floor.',
        targetLanguage: 'zh-TW'), isNull);
    expect(bundledChineseTranslation('  Our class is in Room 13 on the 1st Floor.  ',
        targetLanguage: 'zh-CN'), '我们班在一楼的13号教室。');
  });
}
