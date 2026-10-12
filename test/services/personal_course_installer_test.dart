import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_loop/database/app_database.dart';
import 'package:echo_loop/services/personal_course_installer.dart';

class CourseAssets extends AssetBundle {
  bool fail = false;
  @override
  Future<ByteData> load(String key) async {
    if (fail) throw StateError('模拟课程资源读取失败');
    final content = key.endsWith('.json')
        ? '{"duration":30}'
        : key.endsWith('.srt')
            ? '1\n00:00:00,000 --> 00:00:01,000\nHello.\n'
            : 'audio';
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SharedPreferences prefs;
  late Directory directory;
  late CourseAssets assets;
  PersonalCourseInstaller installer() => PersonalCourseInstaller(
    db, prefs, bundle: assets, dataDirectory: () async => directory,
  );
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    directory = await Directory.systemTemp.createTemp('personal_courses_test_');
    assets = CourseAssets();
  });
  tearDown(() async {
    await db.close();
    // 临时资源由云端构建机回收，测试不批量删除目录或文件。
  });
  test('已有用户材料也添加新课程，重复启动不覆盖用户修改', () async {
    final now = DateTime.now();
    await db.into(db.audioItems).insert(AudioItemsCompanion.insert(
      id: 'user-existing', name: '我的材料', addedDate: now, updatedAt: now,
    ));
    await installer().install();
    expect(await db.audioItemDao.getAllActive(), hasLength(10));
    final id = 'personal-course-greetings';
    await (db.update(db.audioItems)..where((t) => t.id.equals(id)))
        .write(const AudioItemsCompanion(name: Value('我的自定义标题')));
    await installer().install();
    expect((await db.audioItemDao.getById(id))?.name, '我的自定义标题');
    expect(await db.audioItemDao.getAllActive(), hasLength(10));
    expect(await db.collectionDao.getAudioIds(
      PersonalCourseInstaller.collectionId), hasLength(9));
  });
  test('资源失败不标记完成，可重试且无重复记录', () async {
    assets.fail = true;
    await expectLater(installer().install(), throwsStateError);
    expect(prefs.getBool(PersonalCourseInstaller.installedKey), isNull);
    expect(await db.audioItemDao.getAllActive(), isEmpty);
    assets.fail = false;
    await installer().install();
    expect(await db.audioItemDao.getAllActive(), hasLength(9));
    expect(prefs.getBool(PersonalCourseInstaller.installedKey), isTrue);
  });
}
