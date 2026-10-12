#define ECHO_LOOP_RECORDING_TAP_TEST 1
#import "Runner-Bridging-Header.h"

// 模拟系统 tap 接口真正抛出 NSException，验证生产桥接边界不会让进程退出。
@interface TestTapNode : NSObject
@property(nonatomic) BOOL shouldThrow;
@property(nonatomic) NSUInteger calls;
@end
@implementation TestTapNode
- (void)installTapOnBus:(AVAudioNodeBus)bus
            bufferSize:(AVAudioFrameCount)size
                format:(AVAudioFormat *)format
                 block:(AVAudioNodeTapBlock)block {
  self.calls += 1;
  if (self.shouldThrow) {
    @throw [NSException exceptionWithName:@"RecordingTapUnavailable"
                                  reason:@"Simulated invalid audio route"
                                userInfo:nil];
  }
}
@end

int main(void) {
  @autoreleasepool {
    TestTapNode *node = [TestTapNode new];
    AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:48000 channels:1];
    AVAudioNodeTapBlock block = ^(AVAudioPCMBuffer *buffer, AVAudioTime *time) {};
    NSString *error = EchoLoopInstallRecordingTap((AVAudioNode *)(id)node, format, block);
    if (error != nil || node.calls != 1) return 1;
    node.shouldThrow = YES;
    error = EchoLoopInstallRecordingTap((AVAudioNode *)(id)node, format, block);
    if (error.length == 0 || node.calls != 2) return 2;
    node.shouldThrow = NO;
    error = EchoLoopInstallRecordingTap((AVAudioNode *)(id)node, format, block);
    if (error != nil || node.calls != 3) return 3;
    NSLog(@"Recording tap success, exception conversion, and retry passed.");
    return 0;
  }
}
