import 'package:echo_loop/database/daos/sentence_ai_cache_dao.dart';
import 'package:echo_loop/providers/sentence_ai_provider.dart';
import 'package:echo_loop/services/apple_sentence_translation.dart';
import 'package:echo_loop/services/sentence_ai_api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Dao extends Mock implements SentenceAiCacheDao {}
class _Api extends Mock implements SentenceAiApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const text = 'This online lesson is available today.';
  test('系统译文无需登录，也不消耗云端额度', () async {
    final dao = _Dao();
    final api = _Api();
    when(() => dao.getByHash(any(), any())).thenAnswer((_) async => null);
    when(() => dao.upsert(any(), any(), any())).thenAnswer((_) async {});
    var translated = 0;
    final ai = SentenceAiNotifier(
      cacheDao: dao, apiClient: api,
      deviceTranslation: (source) async {
        expect(source, text);
        translated++;
        return '今天可以学习这节在线课程。';
      },
      guardFeature: (_) => throw StateError('不应检查云端额度'),
      onConsumeTrial: (_) => throw StateError('不应消耗云端额度'),
    );
    expect((await ai.getTranslationStream(text, targetLanguage: 'zh-CN').last)
        .translation, '今天可以学习这节在线课程。');
    await ai.getTranslationStream(text, targetLanguage: 'zh-CN').last;
    expect(translated, 1);
    verifyNoMoreInteractions(api);
  });

  test('系统取消或失败不会缓存错误结果', () async {
    final dao = _Dao();
    when(() => dao.getByHash(any(), any())).thenAnswer((_) async => null);
    final ai = SentenceAiNotifier(
      cacheDao: dao, apiClient: _Api(),
      deviceTranslation: (_) async => throw StateError('取消'),
    );
    await expectLater(
      ai.getTranslationStream(text, targetLanguage: 'zh-CN').last,
      throwsStateError,
    );
    expect(ai.getCachedTranslation(text, targetLanguage: 'zh-CN'), isNull);
    verifyNever(() => dao.upsert(any(), any(), any()));
  });

  test('平台桥接把英语发给系统并返回中文', () async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AppleSentenceTranslation.channel, (call) async {
      expect(call.method, 'translate');
      expect(call.arguments, {'text': text});
      return '中文译文';
    });
    try {
      expect(await const AppleSentenceTranslation().translate(text), '中文译文');
    } finally {
      messenger.setMockMethodCallHandler(AppleSentenceTranslation.channel, null);
    }
  });

  test('系统不支持时明确失败，不返回伪造译文', () async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AppleSentenceTranslation.channel, (_) async {
      throw PlatformException(code: 'unsupported');
    });
    try {
      await expectLater(const AppleSentenceTranslation().translate(text),
        throwsA(isA<PlatformException>()));
    } finally {
      messenger.setMockMethodCallHandler(AppleSentenceTranslation.channel, null);
    }
  });
  test('整课译文保持句序并拒绝缺失句子', () async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AppleSentenceTranslation.channel, (call) async {
      expect(call.method, 'translateBatch');
      expect(call.arguments, {'texts': ['First.', 'Second.']});
      return ['第一句。', '第二句。'];
    });
    try {
      expect(await const AppleSentenceTranslation().translateBatch(['First.', 'Second.']),
        ['第一句。', '第二句。']);
      messenger.setMockMethodCallHandler(AppleSentenceTranslation.channel, (_) async => ['缺了一句']);
      await expectLater(
        const AppleSentenceTranslation().translateBatch(['First.', 'Second.']),
        throwsFormatException,
      );
    } finally {
      messenger.setMockMethodCallHandler(AppleSentenceTranslation.channel, null);
    }
  });

}
