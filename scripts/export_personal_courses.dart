import 'dart:convert';
import '../lib/data/personal_courses.dart';

/// 构建语音直接读取App的同一份课程，避免英文和字幕各维护一份。
void main() {
  print(jsonEncode([
    for (final course in personalCourses)
      [course.id, course.title, course.sentences],
  ]));
}
