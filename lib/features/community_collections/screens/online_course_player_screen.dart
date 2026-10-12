import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/regional_service_endpoints.dart';
import '../../../providers/media_engine/media_engine_provider.dart';
import '../../../providers/sentence_ai_provider.dart';
import '../../../services/app_logger.dart';
import '../../../services/apple_sentence_translation.dart';
import '../data/community_collection_api.dart';
import '../models/community_collection_models.dart';

/// 个人中文版本使用已验证提供同路径资源的中国CDN，保留完整路径和查询。
/// 仅替换作者的全球资源域名；第三方音频和已经是中国CDN的地址原样保留。
String personalOnlineMediaUrl(String value) {
  final source = Uri.tryParse(value);
  if (source == null || source.scheme != 'https' ||
      source.userInfo.isNotEmpty || source.hasPort ||
      source.host != Uri.parse(globalModelCdnBaseUrl).host) {
    return value;
  }
  final china = Uri.parse(chinaModelCdnBaseUrl);
  return source.replace(scheme: china.scheme, host: china.host).toString();
}

/// 可替换的整课翻译入口，页面测试不依赖原生系统或网络翻译服务。
final onlineCourseTranslationProvider =
    Provider<Future<List<String>> Function(List<String>)>((ref) =>
        const AppleSentenceTranslation().translateBatch);

/// 从公开课程详情读取字幕并直接播放HTTPS媒体，不创建本地课程文件。
class OnlineCoursePlayerScreen extends ConsumerStatefulWidget {
  const OnlineCoursePlayerScreen({
    super.key, required this.collectionId, required this.file,
  });
  final String collectionId;
  final CommunityCollectionFile file;

  @override
  ConsumerState<OnlineCoursePlayerScreen> createState() =>
      _OnlineCoursePlayerScreenState();
}

class _OnlineCoursePlayerScreenState extends ConsumerState<OnlineCoursePlayerScreen> {
  late final MediaEngine _engine;
  final _cancel = CancelToken();
  final _translations = <int, String>{};
  final _subscriptions = <StreamSubscription<Object?>>[];
  List<CommunitySubtitleSentence> _sentences = const [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = true;
  bool _playing = false;
  String? _error;
  String? _notice;
  double _speed = 1.0;
  int? _translating;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _engine = ref.read(mediaEngineProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _generation++;
    _cancel.cancel('online course closed');
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    // 原播放器采用统一队列解绑，保留原生后端供后续页面复用。
    scheduleMicrotask(() {
      unawaited(_engine.releaseForOwnerDispose());
    });
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true; _error = null; _notice = null;
      _translations.clear();
    });
    try {
      var file = widget.file;
      List<CommunitySubtitleSentence> sentences = const [];
      try {
        final detail = await ref.read(communityCollectionApiProvider)
            .getFileDetail(widget.collectionId, file.id, cancelToken: _cancel);
        file = detail.file;
        sentences = detail.subtitle.sentences;
      } on CommunitySubtitleUnavailable {
        _notice = '此课暂无字幕，仍可播放音频。';
      }
      if (!mounted || generation != _generation) return;
      final duration = await _engine.loadRemoteMedia(
        id: 'online:${file.id}', title: file.title,
        url: personalOnlineMediaUrl(file.mediaUrl),
        speed: _speed,
      );
      if (!mounted || generation != _generation) return;
      if (duration == null) {
        throw StateError(ref.read(mediaEngineProvider).errorMessage ?? '无法连接课程音频');
      }
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      _subscriptions.add(_engine.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      }));
      _subscriptions.add(_engine.playingStream.listen((playing) {
        if (mounted) setState(() => _playing = playing);
      }));
      setState(() {
        _sentences = sentences;
        _duration = duration;
        _loading = false;
      });
      await _prepareChinese();
      if (mounted && generation == _generation) await _engine.play();
    } catch (error) {
      if (!mounted || generation != _generation || _cancel.isCancelled) return;
      AppLogger.log('OnlineCourse', 'load failed: ${error.runtimeType}');
      setState(() {
        _loading = false;
        _error = error is DioException && error.response?.statusCode == 403
            ? '资源服务器拒绝访问（403）。需要恢复课程服务访问，重新登录或下载本地文件不能解决此错误。'
            : '课程暂时无法播放，请检查网络后重试。若课程已下架，需要选择其他课程。';
      });
    }
  }

  /// 播放操作失败时给出提示，不让异步异常静默丢失。
  Future<void> _command(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      AppLogger.log('OnlineCourse', 'playback failed: ${error.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('播放操作失败，请重试。')),
        );
      }
    }
  }

  /// 打开课程时准备所有字幕的中文，失败保留英文并提供整课重试。
  Future<void> _prepareChinese() async {
    if (_sentences.isEmpty || _translating != null) return;
    final generation = _generation;
    final missing = [
      for (var index = 0; index < _sentences.length; index++)
        if (!_translations.containsKey(index) &&
            _sentences[index].text.trim().isNotEmpty) index,
    ];
    if (missing.isEmpty) return;
    setState(() => _translating = -1);
    try {
      final result = await ref.read(onlineCourseTranslationProvider)(
        missing.map((index) => _sentences[index].text).toList(),
      );
      if (result.length != missing.length ||
          result.any((text) => text.trim().isEmpty)) {
        throw const FormatException('译文不完整');
      }
      if (mounted && generation == _generation) {
        setState(() {
          for (var index = 0; index < missing.length; index++) {
            _translations[missing[index]] = result[index];
          }
          _notice = null;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _notice = '中文尚未准备好，可重试中英对照；英文音频仍可播放。');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _translating = null);
      }
    }
  }

  Future<void> _translate(int index) async {
    if (_translating != null) return;
    final generation = _generation;
    setState(() => _translating = index);
    try {
      await _engine.pause();
      if (!mounted || generation != _generation) return;
      final result = await ref.read(sentenceAiNotifierProvider)
          .getTranslationStream(_sentences[index].text, targetLanguage: 'zh-CN')
          .last;
      if (mounted && generation == _generation) {
        setState(() => _translations[index] = result.translation);
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('中文翻译暂不可用，请完成系统语言准备后重试。')),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _translating = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.file.title)),
      body: _loading
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('正在连接在线课程…')],
            ))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? '')),
                  FilledButton(onPressed: _load, child: const Text('重试')),
                ]))
              : Column(children: [
                  if (widget.file.mediaType == CommunityMediaType.video)
                    SizedBox(height: 200, child: LayoutBuilder(
                      builder: (_, constraints) => _engine.buildVideoView(
                        viewportSize: Size(constraints.maxWidth, 200),
                      ),
                    )),
                  if (_notice != null) Padding(
                    padding: const EdgeInsets.all(8), child: Text(_notice ?? ''),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('在线播放 · 英文下方显示中文 · 点句子从这里听'),
                  ),
                  if (_sentences.isNotEmpty &&
                      _translations.length < _sentences.where((s) => s.text.trim().isNotEmpty).length)
                    TextButton(
                      onPressed: _translating == null ? _prepareChinese : null,
                      child: Text(_translating == -1 ? '正在准备本课中文…' : '重试中英对照'),
                    ),
                  Slider(
                    value: _position.inMilliseconds.toDouble()
                        .clamp(0, _duration.inMilliseconds.toDouble()),
                    max: _duration.inMilliseconds > 0
                        ? _duration.inMilliseconds.toDouble() : 1,
                    onChanged: (value) => unawaited(_command(
                      () => _engine.seek(Duration(milliseconds: value.round())),
                    )),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                      icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      tooltip: _playing ? '暂停' : '播放',
                      onPressed: () => unawaited(_command(
                        _playing ? _engine.pause : _engine.play,
                      )),
                    ),
                    DropdownButton<double>(
                      value: _speed,
                      items: [0.75, 1.0, 1.25].map((rate) =>
                        DropdownMenuItem(value: rate, child: Text('$rate倍速'))).toList(),
                      onChanged: (rate) {
                        if (rate == null) return;
                        setState(() => _speed = rate);
                        unawaited(_command(() => _engine.setSpeed(rate)));
                      },
                    ),
                  ]),
                  Expanded(child: ListView.builder(
                    itemCount: _sentences.length,
                    itemBuilder: (_, index) {
                      final sentence = _sentences[index];
                      final current = _position >= sentence.startTime &&
                          _position < sentence.endTime;
                      return ListTile(
                        selected: current,
                        title: Text(sentence.text),
                        subtitle: _translations[index] == null
                            ? Text(_translating == -1 ? '正在准备中文…' : '中文尚未准备好')
                            : Text(_translations[index] ?? ''),
                        onTap: () => unawaited(_command(() async {
                          await _engine.seek(sentence.startTime);
                          await _engine.play();
                        })),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: '重听本句',
                            icon: const Icon(Icons.replay),
                            onPressed: () => unawaited(_command(() async {
                              await _engine.playRange(
                                sentence.startTime, sentence.endTime, speed: _speed,
                              );
                            })),
                          ),
                          TextButton(
                            onPressed: _translating == null ? () => _translate(index) : null,
                            child: Text(_translating == index ? '翻译中' : '中文'),
                          ),
                        ]),
                      );
                    },
                  )),
                ]),
    );
  }
}
