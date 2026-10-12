import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/personal_courses.dart';
import '../database/app_database.dart';
import '../utils/app_data_dir.dart';

/// 更新时也安装个人课程；事务和版本标记避免重复，并保留原有数据。
class PersonalCourseInstaller {
  PersonalCourseInstaller(this.db, this.prefs, {
    AssetBundle? bundle,
    Future<Directory> Function()? dataDirectory,
  }) : bundle = bundle ?? rootBundle,
       dataDirectory = dataDirectory ?? getAppDataDirectory;

  final AppDatabase db;
  final SharedPreferences prefs;
  final AssetBundle bundle;
  final Future<Directory> Function() dataDirectory;
  static const installedKey = 'personal_courses_v1_installed';
  static const collectionId = 'personal-courses-v1';

  Future<void> install() async {
    if (prefs.getBool(installedKey) ?? false) return;
    final dir = await dataDirectory();
    final mediaDir = Directory(p.join(dir.path, 'personal_courses'));
    await mediaDir.create(recursive: true);
    final durations = <String, int>{};
    final subtitles = <String, String>{};
    for (final course in personalCourses) {
      final base = 'assets/demo/personal-${course.id}';
      final meta = jsonDecode(await bundle.loadString('$base.json'));
      if (meta is! Map<String, dynamic> || meta['duration'] is! int) {
        throw FormatException('课程时长无效: ${course.id}');
      }
      final duration = meta['duration'];
      if (duration is! int || duration <= 0) {
        throw FormatException('课程时长无效: ${course.id}');
      }
      durations[course.id] = duration;
      subtitles[course.id] = await bundle.loadString('$base.srt');
      final bytes = await bundle.load('$base.wav');
      await File(p.join(mediaDir.path, '${course.id}.wav')).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }
    await db.transaction(() async {
      final now = DateTime.now();
      await db.into(db.collections).insertOnConflictUpdate(
        CollectionsCompanion.insert(
          id: collectionId, name: '我的入门与电商英语 · 合成语音',
          createdDate: now, updatedAt: now,
        ),
      );
      for (var i = 0; i < personalCourses.length; i++) {
        final course = personalCourses[i];
        final id = 'personal-course-${course.id}';
        // 保留升级前已有或用户编辑过的条目，失败重试不会覆盖学习进度。
        final existing = await (db.select(db.audioItems)
          ..where((t) => t.id.equals(id))).getSingleOrNull();
        if (existing != null) continue;
        await db.into(db.audioItems).insert(AudioItemsCompanion.insert(
          id: id, name: course.title,
          audioPath: Value('personal_courses/${course.id}.wav'),
          addedDate: now, updatedAt: now,
          totalDuration: Value(durations[course.id] ?? 0),
          sentenceCount: Value(course.sentences.length),
          wordCount: Value(course.sentences.fold<int>(
            0, (count, text) => count + text.split(RegExp(r'\s+')).length)),
          transcriptSource: const Value(0),
          transcriptLanguage: const Value('en'),
          transcriptSrt: Value(subtitles[course.id]),
        ));
        await db.into(db.collectionAudioItems).insert(
          CollectionAudioItemsCompanion.insert(
            collectionId: collectionId, audioItemId: id,
            sortOrder: Value(i), addedAt: now,
          ),
        );
      }
    });
    await prefs.setBool(installedKey, true);
  }
}
