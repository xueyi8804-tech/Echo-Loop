#ifndef ECHO_LOOP_RECORDING_TAP_TEST
#import "GeneratedPluginRegistrant.h"
#endif
#import <AVFoundation/AVFoundation.h>

// AVAudioNode 的旧 tap 接口抛出 Objective-C 异常，Swift do/catch 无法捕获。
// 在边界处转换为可显示的错误，避免麦克风初始化失败直接终止 App。
static inline NSString * _Nullable EchoLoopInstallRecordingTap(
    AVAudioNode * _Nonnull node,
    AVAudioFormat * _Nonnull format,
    AVAudioNodeTapBlock _Nonnull block) {
  @try {
    [node installTapOnBus:0 bufferSize:1024 format:format block:block];
    return nil;
  } @catch (NSException *exception) {
    return @"麦克风初始化失败，请关闭蓝牙耳机并重新打开 App 后重试。";
  }
}
