import 'package:flutter/services.dart';

/// 调用iPhone系统英译中；语言资源由系统征求用户同意后准备。
class AppleSentenceTranslation {
  const AppleSentenceTranslation();
  static const channel = MethodChannel('top.echo-loop/system_translation');

  Future<String> translate(String text) async {
    if (text.trim().isEmpty) throw const FormatException('没有要翻译的句子');
    final result = await channel.invokeMethod<String>('translate', {'text': text});
    if (result == null || result.trim().isEmpty) {
      throw const FormatException('系统未返回中文译文');
    }
    return result;
  }
}
