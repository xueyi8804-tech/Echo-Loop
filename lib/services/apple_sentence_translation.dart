import 'package:flutter/services.dart';

/// 调用iPhone系统英译中；语言资源由系统征求用户同意后准备。
class AppleSentenceTranslation {
  const AppleSentenceTranslation();
  static const channel = MethodChannel('top.echo-loop/system_translation');

  /// 一次准备整课中文；结果按输入句序对应，不拼接或猜测分句。
  Future<List<String>> translateBatch(List<String> texts) async {
    if (texts.isEmpty) return const [];
    if (texts.any((text) => text.trim().isEmpty)) {
      throw const FormatException('课程含空句子');
    }
    final result = await channel.invokeListMethod<String>(
      'translateBatch', {'texts': texts},
    );
    if (result == null || result.length != texts.length ||
        result.any((text) => text.trim().isEmpty)) {
      throw const FormatException('系统返回的整课译文不完整');
    }
    return result;
  }

  Future<String> translate(String text) async {
    if (text.trim().isEmpty) throw const FormatException('没有要翻译的句子');
    final result = await channel.invokeMethod<String>('translate', {'text': text});
    if (result == null || result.trim().isEmpty) {
      throw const FormatException('系统未返回中文译文');
    }
    return result;
  }
}
