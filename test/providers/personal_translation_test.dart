import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo_loop/data/personal_courses.dart';
import 'package:echo_loop/database/app_database.dart';
import 'package:echo_loop/providers/sentence_ai_provider.dart';
import 'package:echo_loop/services/sentence_ai_api_client.dart';

void main() {
  test('所有个人课程原句都有预置中文', () {
    for (final course in personalCourses) {
      for (final sentence in course.sentences) {
        expect(personalChineseTranslation(sentence, 'zh-CN'), isNotEmpty);
      }
    }
    expect(personalChineseTranslation('unknown', 'zh-CN'), isNull);
    expect(personalChineseTranslation('Nice to meet you.', 'ja'), isNull);
  });

  test('没有登录、数据库或网络时，预置翻译直接可用且不计额度', () async {
    final db = AppDatabase(NativeDatabase.memory());
    var consumed = 0;
    final ai = SentenceAiNotifier(
      cacheDao: db.sentenceAiCacheDao,
      apiClient: SentenceAiApiClient(baseUrl: 'http://127.0.0.1:1'),
      guardFeature: (_) => throw StateError('不应检查云端额度'),
      onConsumeTrial: (_) => consumed++,
    );
    try {
      final result = await ai.getTranslationStream(
        'Our class is in Room 13 on the 1st Floor.',
        targetLanguage: 'zh-CN',
      ).toList();
      expect(result.single.translation, '我们在一楼的13号教室上课。');
      expect(ai.getCachedTranslation(
        'Please speak slowly.', targetLanguage: 'zh-CN',
      )?.translation, '请说慢一点。');
      expect(consumed, 0);
    } finally {
      await db.close();
    }
  });
}
