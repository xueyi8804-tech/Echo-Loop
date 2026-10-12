import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:echo_loop/models/media_engine_state.dart';
import 'package:dio/dio.dart';
import 'package:echo_loop/features/community_collections/data/community_collection_api.dart';
import 'package:echo_loop/features/community_collections/models/community_collection_models.dart';
import 'package:echo_loop/features/community_collections/screens/online_course_player_screen.dart';
import 'package:echo_loop/providers/media_engine/media_engine_provider.dart';
import 'package:echo_loop/services/media_session_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:echo_loop/features/community_collections/widgets/community_collection_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/shared/fake_media_player_backend.dart';
import '../../helpers/test_app.dart';

class _Api extends Mock implements CommunityCollectionApi {}

/// 页面测试替换媒体控制器；真实引擎到URL后端的边界由上面的单元测试覆盖。
class _PageEngine extends MediaEngine {
  _PageEngine(this.backend);
  final FakeMediaPlayerBackend backend;
  @override
  MediaEngineState build() => const MediaEngineState();
  @override
  Future<Duration?> loadRemoteMedia({
    required String id, required String title, required String url, double speed = 1,
  }) async {
    await backend.open(url);
    await backend.setRate(speed);
    return backend.duration;
  }
  @override
  Stream<Duration> get positionStream => backend.positionStream;
  @override
  Stream<bool> get playingStream => backend.playingStream;
  @override
  Future<void> play() => backend.play();
  @override
  Future<void> pause() => backend.pause();
  @override
  Future<void> seek(Duration position) => backend.seek(position);
  @override
  Future<void> releaseForOwnerDispose() => backend.stop();
}

const _file = CommunityCollectionFile(
  id: 'online-1', title: 'Public lesson', description: null,
  mediaType: CommunityMediaType.audio, durationSec: 10, fileSizeBytes: null,
  difficulty: null, publishedAt: null, sortOrder: 0,
  mediaUrl: 'https://example.com/public-lesson.m4a',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(CancelToken()));

  test('网络媒体直接交给后端，不解析为本地音频文件', () async {
    final backend = FakeMediaPlayerBackend();
    final container = ProviderContainer(overrides: [
      mediaBackendFactoryProvider.overrideWithValue(() => backend),
      mediaSessionRouterProvider.overrideWithValue(
        MediaSessionRouter(defaultHandler: BaseAudioHandler())),
    ]);
    final engine = container.read(mediaEngineProvider.notifier);
    try {
      expect(await engine.loadRemoteMedia(
        id: 'public', title: '公开课', url: _file.mediaUrl,
      ), const Duration(seconds: 10));
      expect(backend.openCalls, [_file.mediaUrl]);
      expect(container.read(mediaEngineProvider).currentMediaId, 'public');
    } finally {
      await engine.disposeChain();
      container.dispose();
    }
  });

  test('拒绝文件路径和非HTTPS地址，不打开播放后端', () async {
    final backend = FakeMediaPlayerBackend();
    final container = ProviderContainer(overrides: [
      mediaBackendFactoryProvider.overrideWithValue(() => backend),
    ]);
    try {
      await expectLater(
        container.read(mediaEngineProvider.notifier).loadRemoteMedia(
          id: 'bad', title: 'bad', url: 'file:///private/data'),
        throwsFormatException,
      );
      expect(backend.openCalls, isEmpty);
    } finally {
      container.dispose();
    }
  });

  testWidgets('个人在线入口打开课程，不调用加入账号合集', (tester) async {
    var opened = 0;
    var enrolled = 0;
    await tester.pumpWidget(createTestApp(
      CommunityCollectionCard(
        item: PublicCollectionCatalogEntry(
          id: 'c', name: 'A1', description: null, coverUrl: null,
          fileCount: 52, publishedAt: DateTime(2026, 10, 12),
        ),
        onlineOnly: true, enrolled: false, enrolling: false,
        onOpenDetail: () => opened++,
        onEnroll: () => enrolled++,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('在线播放'));
    expect(opened, 1);
    expect(enrolled, 0);
  });

  testWidgets('未登录可读取公开字幕、播放URL并点句跳转', (tester) async {
    final api = _Api();
    final backend = FakeMediaPlayerBackend();
    when(() => api.getFileDetail('c', _file.id,
      cancelToken: any(named: 'cancelToken'))).thenAnswer((_) async =>
      const CommunityCollectionFileDetail(
        file: _file,
        subtitle: CommunitySubtitle(sentences: [
          CommunitySubtitleSentence(text: 'A public sentence.',
            startTime: Duration(seconds: 2), endTime: Duration(seconds: 5)),
        ], words: []),
      ));
    await tester.pumpWidget(createTestApp(
      const OnlineCoursePlayerScreen(collectionId: 'c', file: _file),
      overrides: [
        communityCollectionApiProvider.overrideWithValue(api),
        onlineCourseTranslationProvider.overrideWithValue((texts) async {
          expect(texts, ['A public sentence.']);
          return ['这是一句公开课程的字幕。'];
        }),
        mediaEngineProvider.overrideWith(() => _PageEngine(backend)),
      ],
    ));
    await tester.pumpAndSettle();
    expect(backend.openCalls, [_file.mediaUrl]);
    expect(backend.playCalls, 1);
    expect(find.text('A public sentence.'), findsOneWidget);
    expect(find.text('这是一句公开课程的字幕。'), findsOneWidget);
    expect(find.text('重试中英对照'), findsNothing);
    expect(find.text('登录'), findsNothing);
    await tester.tap(find.text('A public sentence.'));
    await tester.pumpAndSettle();
    expect(backend.seekCalls.last, const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await backend.dispose();
  });
}
